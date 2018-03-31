#!/bin/bash

ROCE_TOP_DIR=$( cd "`dirname $0`" ; pwd )
ROCE_CASE_DIR=${ROCE_TOP_DIR}/case_script

# Load the public configuration library
. ${ROCE_TOP_DIR}/../config/common_config
. ${ROCE_TOP_DIR}/../config/common_lib

# Load module configuration library
. ${ROCE_TOP_DIR}/config/roce_test_config
. ${ROCE_TOP_DIR}/config/roce_test_lib

# Main operation function
# IN : N/A
# OUT: N/A
function main()
{
    Module_Name="ROCE"
    echo "Begin to run "$Module_Name" test"
	local MaxRow=$(sed -n '$=' "${ROCE_TOP_DIR}/${TEST_CASE_DB_FILE}")
	local RowNum=0

	while [ ${RowNum} -lt ${MaxRow} ]
	do
		let RowNum+=1
		local line=$(sed -n "${RowNum}p" "${ROCE_TOP_DIR}/${TEST_CASE_DB_FILE}")

		exec_script=`echo "${line}" | awk -F '\t' '{print $6}'`
		TEST_CASE_FUNCTION_NAME=`echo "${line}" | awk -F '\t' '{print $7}'`
		TEST_CASE_FUNCTION_SWITCH=`echo "${line}" | awk -F '\t' '{print $8}'`
                
                TEST_CASE_TITLE=`echo "${line}" | awk -F '\t' '{print $3}'`

                echo "TestCaseInfo "${TEST_CASE_TITLE}" "${exec_script}" "${TEST_CASE_FUNCTION_NAME}" "${TEST_CASE_FUNCTION_SWITCH} 

		if [ x"${exec_script}" == x"" ]
		then
			MESSAGE="unimplemented automated test cases."
			echo ${MESSAGE}
		else
			if [ ! -f "${ROCE_CASE_DIR}/${exec_script}" ]
			then
				MESSAGE="FILE\tcase_script/${exec_script} execution script does not exist, please check."
				echo ${MESSAGE}
			else
				if [ x"${TEST_CASE_FUNCTION_SWITCH}" == x"on"  ]
				then
			        	echo "Begint to run test "${TEST_CASE_TITLE}
					source ${ROCE_CASE_DIR}/${exec_script}
				else
					echo "Skip the script!"
				fi
			fi
		fi
		echo -e "${line}${MESSAGE}" >> ${ROCE_TOP_DIR}/${OUTPUT_TEST_DB_FILE}
		MESSAGE=""
		#echo "Done test: "${TEST_CASE_TITLE}
	done
}

#
insmod /home/kernel/output/hns-roce.ko
insmod /home/kernel/output/hns-roce-hw-v1.ko



LOCAL_ETHX=`cat /sys/class/infiniband/hns_0/ports/${ROCE_PORT}/gid_attrs/ndevs/0`


#roce test is only excute in 159 dash board
#Find the local MAC
tmpMAC=`ifconfig eth0 | grep "HWaddr" | awk '{print $NF}'`
if [ x"${tmpMAC}" = x"${BOARD_159_MAC_ADDR}" ]
then
	echo "ROCE test can be excute in this board!"
else
	echo "ROCE test can not be excute in this board,exit!"
	exit 0
fi

#Get Local IP
initLocalIP 
LOCAL_IP=${COMMON_LOCAL_IP}
echo ${LOCAL_IP}

#Get client ip
getIPofClientServer ${DHCP_SERVER_MAC_ADDR} ${CLIENT_SERVER_MAC_ADDR} ${DHCP_SERVER_USER} ${DHCP_SERVER_PASS}

if [ x"${COMMON_CLIENT_IP}" = x"" ]
then
	echo "No found client IP,try ping default DHCP ip to update arp list!"
        ping ${COMMON_DEFAULT_DHCP_IP} -c 5
        getIPofClientServer ${DHCP_SERVER_MAC_ADDR} ${CLIENT_SERVER_MAC_ADDR} ${DHCP_SERVER_USER} ${DHCP_SERVER_PASS}
        if [ x"${COMMON_CLIENT_IP}" = x"" ]
        then
		echo "Can not find the client IP, exit hns test!"
                exit 0
        fi
fi

BACK_IP=${COMMON_CLIENT_IP}
echo "The client ip is "${BACK_IP}

#get BACK_IP according host's ip
#Init_Net_Ip
init_net_export

TrustRelation ${BACK_IP}

Set_Test_Ip

copy_tool_so

#
#scp /home/kernel/output/hns-roce.ko root@${BACK_IP}:/home/tmp/
#scp /home/kernel/output/hns-roce-hw-v1.ko root@${BACK_IP}:/home/tmp/
#ssh root@${BACK_IP} "insmod /home/tmp/hns-roce.ko"
#ssh root@${BACK_IP} "insmod /home/tmp/hns-roce-hw-v1.ko


#********
#****Start : Clone roce user driver repo and build it
#********

#save the current path
save_path=`pwd`

#cd into the repo
tmp=`echo ${ROCE_USERDRV_GITADDR} | awk -F'.' '{print $2}' | awk -F'/' '{print $NF}'`
echo "The name of kernel repo is "$tmp

#checkout if roce user driver repo is exit or not!
mkdir /home/luojiaxing/

if [ ! -d "/home/luojiaxing/${tmp}" ];then
	echo "The roce user driver repo is not exit! Begin to clone repo!"
        cd /home/luojiaxing
        git clone ${KERNEL_GITADDR}
else
	echo "The kernel repo have been found!"
fi

cd /home/luojiaxing/${tmp}

#checkout specified branch and build keinel
git branch | grep ${ROCE_USERDRV_BRANCH}

if [ $? -eq 0 ];then
	#The same name of branch is exit
	git checkout -b tmp_luo origin/${ROCE_USERDRV_BRANCH}
	git branch -D ${ROCE_USERDRV_BRANCH}
fi

git checkout -b ${ROCE_USERDRV_BRANCH} origin/${ROCE_USERDRV_BRANCH}
git branch -D tmp_luo

echo "Begin to build the roce user driver!"
bash build.sh 

echo "Finish the roce user driver build!"

#copy the so to /lib document
cd build/lib/
mkdir luo
cp -a libhns-rdmav* luo/
cp -a libibverbs.so* luo/
cp -a libibumad.so* luo/
cp -a librdmacm.so* luo/

cp -a luo/* /lib/

#copy the user driver to client's /lib/
tar zcvf roce_user_drv.tar.gz luo
scp roce_user_drv.tar.gz root@${BACK_IP}:/home/kernel/lib/

ssh root@${BACK_IP} "cd /home/kernel/lib/;tar zxvf roce_user_drv.tar.gz;cp -a luo/* /lib/"
ssh root@${BACK_IP} "rm -r /home/kernel/lib/luo/"
ssh root@${BACK_IP} "rm /home/kernel/lib/roce_user_drv.tar.gz"

rm -r luo/
rm roce_user_drv.tar.gz 

echo "Finish copy the roce user driver to /lib/"

cd ${save_path}

#********
#****END : Clone roce user driver repo and build it
# Output log file header

#kill roce process running before
/${ROCE_TOP_DIR}/case_script/roce-test -m 2 -c 0xff -r
ssh root@${BACK_IP} "/root/roce-test/roce-test -m 2 -c 0xff -r"
sleep 10

writeLogHeader

main

#kill roce process running before
/${ROCE_TOP_DIR}/case_script/roce-test -m 2 -c 0xff -r
ssh root@${BACK_IP} "/root/roce-test/roce-test -m 2 -c 0xff -r"
sleep 10

# clean exit so lava-test can trust the results
exit 0


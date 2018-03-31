#!/bin/bash

PRE_TOP_DIR=$(cd "`dirname $0`" ; pwd)

# Load the public configuration library
. ${PRE_TOP_DIR}/../config/common_config
. ${PRE_TOP_DIR}/../config/common_lib

envok=0

#**Check if board is support this test suite according to MAC address

#Find the local MAC
tmpMAC=`ifconfig eth0 | grep "HWaddr" | awk '{print $NF}'`
for mac in $TESTBOARD_MAC_LIST
do
	if [ x"${tmpMAC}" = x"${mac}" ]
	then
		echo "Xge test can be excute in this board!"
		envok=1
	else
		echo "Xge test can not be excute in this board,exit!"
	fi
done

#if test env prepare is ok or not
if [ $envok -eq 0 ];then
	echo "some error happen when construct test env!"
	rm ${PRE_TOP_DIR}/ok.log
        lava_report "CI plinth Test prepare: Some test can not run in this board!" fail
	exit 0
fi



#****Check cmd support before running prepare actions for plinth test*****#

#********
#****Start : Clone kernel repo and build it
#********

#cd into the repo
tmp=`echo ${KERNEL_GITADDR} | awk -F'.' '{print $2}' | awk -F'/' '{print $NF}'`
echo "The name of kernel repo is "$tmp

#checkout if kernel repo is exit or not!
if [ ! -d "/home/kernel/${tmp}" ];then
	echo "The kernel dir is not exit! Begin to clone repo!"
        mkdir /home/kernel
        cd /home/kernel
        git clone ${KERNEL_GITADDR}
else
	echo "The kernel repo have been found!"
fi

cd /home/kernel/${tmp}

#generate the patch of pmu v2 to make perf support in D05
git stash
git checkout -b svm-4.15 remotes/origin/release-plinth-4.15.0
tmp_patch=`git format-patch -1 b4e84aac21e48fcccc964216be5c7f8530db7b32`

cp ${tmp_patch}  /home/kernel/output/

#checkout specified branch and build keinel
git branch | grep ${BRANCH_NAME}

if [ $? -eq 0 ];then
	#The same name of branch is exit
	git stash
	git checkout -b tmp_luo origin/${BRANCH_NAME}
	git branch -D ${BRANCH_NAME}
fi

git checkout -b ${BRANCH_NAME} origin/${BRANCH_NAME}
git branch -D tmp_luo

#before any change,patch the PMU patch to support D05
git am /home/kernel/output/${tmp_patch}
sleep 20
git branch -D svm-4.15

#patch for enable perf test support
#git am ${PRE_TOP_DIR}/../ci_interface/patch/perf/0001-sparkles-add-perf-test-support-code-for-l3c-and-mn.patch
git am --abort
git am ${PRE_TOP_DIR}/../ci_interface/patch/perf_test_support_l3c_mn.patch
sleep 20

#before building,change some build cfg

#HNS VLAN build option
sed -i 's/CONFIG_VLAN_8021Q=m/CONFIG_VLAN_8021Q=y/g' arch/arm64/configs/defconfig

echo "Begin to build the kernel!"
bash build.sh d05 > ${PRE_TOP_DIR}/ok.log

echo "Finish the kernel build!"

#********
#****END : Clone kernel repo and build it
#********

#********
#****Start : Copy module ko to spcified document
#********

#check ko document is exit or not
if [ ! -d "/home/kernel/output" ];then
	echo "The output dir to save ko is not exit, mkdir!"
	mkdir /home/kernel/output
fi

#copy the ko to specified folder : /home/kernel/output
cp -f drivers/infiniband/hw/hns/hns-roce-hw-v1.ko /home/kernel/output/
cp -f drivers/infiniband/hw/hns/hns-roce.ko /home/kernel/output/

if [ -f "/home/kernel/output/hns-roce.ko" ];then
	echo "Finish copy the ko to output dir!"
else
	echo "No found the ko file!Maybe the build is fail!"
        lava_report "CI plinth Test prepare: Fail to generate ko file!" fail
       	envok=0 
fi
#********
#****END : Copy module ko to spcified document
#********


#********
#***Start : Prepare Boot Disk For selfreboot
#********

#mkfs the boot disk:sda1
mkfs.vfat ${BOOT_DISK}

#copy the Image to bootdisk to support disk reboot
if [ ! -d "/home/kernel/a1" ];then
	mkdir /home/kernel/a1
fi

#mount boot disc
mount /dev/sda1 /home/kernel/a1

#copy Image to boot disc
cp -f arch/arm64/boot/Image /home/kernel/a1

if [ -f "/home/kernel/a1/Image" ];then
	echo "Finish copy the Image to output dir!"
else
	echo "No found the Image file!Maybe the build is fail!"
        lava_report "CI plinth Test prepare: Fail to generate Image file!" fail
        envok=0
fi

#copy grub file to boot disc
cp -rf ${PRE_TOP_DIR}/../ci_interface/install/a1/* /home/kernel/a1

if [ -f "/home/kernel/a1/grub.cfg" ];then
	echo "Finish copy the grub.cfg to output dir!"
else
	echo "No found the grub file!Maybe the copy is fail!"
        lava_report "CI plinth Test prepare: Fail to generate grub.cfg file!" fail
        envok=0
fi


#******
#***END : Prepare Boot Disk For selfreboot
#******

#if test env prepare is ok or not
if [ $envok -eq 0 ];then
	echo "some error happen when construct test env!"
	rm ${PRE_TOP_DIR}/ok.log
else
	echo "Test env contruction is success!"
	lava_report "CI plinth Test prepare: Success" pass
fi


exit 0


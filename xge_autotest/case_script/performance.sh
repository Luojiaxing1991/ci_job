#!/bin/bash
LOG_DIR="perf_log"
IPERFDIR="iperf_log"
NETPERFDIR="netperf_log"
QPERFDIR="qperf_log"

LOCALPORT1="$local_tp1"
LOCALPORT2="$local_fibre1"

LOCALIP1="$local_tp1_ip"
LOCALIP2="$local_fibre1_ip"

NETPORT1="$remote_tp1"
NETPORT2="$remote_fibre1"
NETPORTLIST="$remote_tp1 $remote_fibre1"

NETIP1="$remote_tp1_ip"
NETIP2="$remote_fibre1_ip"
#ipv6 config

#iperf config
THREAD="1 5 10"
IPERFDURATION=20

#netperf config
NETPERFDURATION=5
STREAM_TYPE="TCP_STREAM UDP_STREAM"
RR_TYPE="TCP_RR TCP_CRR UDP_RR"
TCP_MSS="32 64 128 256 512 1024 1500"
UDP_MSS="32 64 128 256 521 1024 4096 16376 32753 65507"

#netport type : XGE,GE
PORT_TYPE=""

#protocol type : VLAN,IPV6,IPV4
PROTOCOL_TYPE=""

function remote_iperf_s()
{
  ssh root@$BACK_IP "iperf -s -V >/dev/null 2>&1 &"
  sleep 5
  
  show=`ssh root@$BACK_IP "ps -ef | grep iperf "`
  echo ${show}

}

function local_iperf_s()
{
  iperf -s -V >/dev/null 2>&1 &
  sleep 5

  show=`ps -ef | grep iperf`
  echo ${show}

}

function usage()
{
    echo "$0 all | iperf | qperf | netperf | ipv6_iperf"
}

function prepare_log_dir()
{
    if [ ! -d $LOG_DIR ]; then
        mkdir $LOG_DIR
    fi
    for log_type in iperf_log qperf_log netperf_log
    do
        if [ ! -d $LOG_DIR/$log_type ]; then
            mkdir $LOG_DIR/$log_type
       # else
            #rm $LOG_DIR/$log_type/*.log
        fi
    done
}

function data_integration()
{
    if [ $SendPyte = "SingleOne" ];then
        echo "Single port one-way ${netport} ${owNum}thread:" >> $LOG_DIR/$IPERFDIR/data_integration.log
        sleep 1
        cat $LOG_DIR/$IPERFDIR/single_one-way_${netport}_${owNum}thread.log | tail -1 >> $LOG_DIR/$IPERFDIR/data_integration.log
        echo -e "\n" >> $LOG_DIR/$IPERFDIR/data_integration.log
        sleep 1
    elif [ $SendPyte = "SingleTwo" ];then
        echo "Single port two-way ${twNum}thread:" >> $LOG_DIR/$IPERFDIR/data_integration.log
        sleep 1
        cat $LOG_DIR/$IPERFDIR/Single_two-way_${NETPORT1}_${twNum}thread.log | tail -1 >> $LOG_DIR/$IPERFDIR/data_integration.log
        cat $LOG_DIR/$IPERFDIR/Single_two-way_${NETPORT2}_${twNum}thread.log | tail -1 >> $LOG_DIR/$IPERFDIR/data_integration.log
        echo -e "\n" >> $LOG_DIR/$IPERFDIR/data_integration.log
        sleep 1
    elif [ $SendPyte = "DualOne" ];then
        echo "Dual port one-way ${netport} ${owNum}thread:" >> $LOG_DIR/$IPERFDIR/data_integration.log
        sleep 1
        cat $LOG_DIR/$IPERFDIR/dual_one-way_local_${netport}_${owNum}thread.log | tail -1 >> $LOG_DIR/$IPERFDIR/data_integration.log
        cat $LOG_DIR/$IPERFDIR/dual_one-way_remote_${netport}_${owNum}thread.log | tail -1 >> $LOG_DIR/$IPERFDIR/data_integration.log
        echo -e "\n" >> $LOG_DIR/$IPERFDIR/data_integration.log
        sleep 1
    else
        echo "Dual port two-way ${twNum}thread:" >> $LOG_DIR/$IPERFDIR/data_integration.log
        sleep 1
        cat $LOG_DIR/$IPERFDIR/dual_twoway_local_${NETPORT1}_${twNum}thread.log | tail -1 >> $LOG_DIR/$IPERFDIR/data_integration.log
        cat $LOG_DIR/$IPERFDIR/dual_twoway_remote_${NETPORT1}_${twNum}thread.log | tail -1 >> $LOG_DIR/$IPERFDIR/data_integration.log
        cat $LOG_DIR/$IPERFDIR/dual_twoway_local_${NETPORT2}_${twNum}thread.log | tail -1 >> $LOG_DIR/$IPERFDIR/data_integration.log
        cat $LOG_DIR/$IPERFDIR/dual_twoway_remote_${NETPORT2}_${twNum}thread.log | tail -1 >> $LOG_DIR/$IPERFDIR/data_integration.log
        echo -e "\n" >> $LOG_DIR/$IPERFDIR/data_integration.log
        sleep 1    
    fi  
} 

function check_single_process()
{
    flag=1
    result=1
    timeoutcnt=0
    while [ "$flag" -eq 1 ]
    do
        echo "Time cnt is "$timeoutcnt
        ((timeoutcnt++))
        sleep 1
        result=`pidof $process`
        if [ -z "$result" ];then
            echo "$process process is finished"
            flag=0
        fi

        if [ $timeoutcnt -gt 30  ]
        then
            echo "The lass process is stock,fail!"
            MESSAGE="FAIL\t iperf time out!"
            break
        fi

    done
}

function check_remote_single_process()
{
    flag=1
    result=1
    timeoutcnt=0
    while [ "$flag" -eq 1 ]
    do
        echo "Time cnt is "$timeoutcnt
        ((timeoutcnt++))
        sleep 1
        result=`ssh root@${BACK_IP} "pidof $process"`
        if [ -z "$result" ];then
            echo "$process process is finished"
            flag=0
        fi

        if [ $timeoutcnt -gt 30  ]
        then
            echo "The lass process is stock,fail!"
            MESSAGE="FAIL\t iperf time out!"
            break
        fi

    done
}



function check_dual_process()
{
    flag=1
    result=1
    timeoutcnt=0
    while [ "$flag" -eq 1 ]
    do
        ((timeoutcnt++))
        sleep 2
        result=`ps -ef | grep $process | wc -l`
        if [ "$result" -le 2 ];then
            echo "$process process is finished"
            flag=0
        fi

        if [ $timeoutcnt -gt 15  ]
        then
            echo "The lass process is stock,fail!"
            break
        fi
    done
}

function ipv6_data_integration()
{
    if [ $SendPyte = "SingleOne" ];then
        echo "Single port one-way ${netport} ${owNum}thread:" >> $LOG_DIR/$IPERFDIR/Ipv6_data_integration.log
        sleep 1
        cat $LOG_DIR/$IPERFDIR/Ipv6_single_one-way_${netport}_${owNum}thread.log | tail -1 >> $LOG_DIR/$IPERFDIR/Ipv6_data_integration.log
        echo -e "\n" >> $LOG_DIR/$IPERFDIR/Ipv6_data_integration.log
        sleep 1
    elif [ $SendPyte = "SingleTwo" ];then
        echo "Single port two-way ${twNum}thread:" >> $LOG_DIR/$IPERFDIR/Ipv6_data_integration.log
        sleep 1
        cat $LOG_DIR/$IPERFDIR/Ipv6_Single_two-way_${NETPORT1}_${twNum}thread.log | tail -1 >> $LOG_DIR/$IPERFDIR/Ipv6_data_integration.log
        cat $LOG_DIR/$IPERFDIR/Ipv6_Single_two-way_${NETPORT2}_${twNum}thread.log | tail -1 >> $LOG_DIR/$IPERFDIR/Ipv6_data_integration.log
        echo -e "\n" >> $LOG_DIR/$IPERFDIR/Ipv6_data_integration.log
        sleep 1
    elif [ $SendPyte = "DualOne" ];then
        echo "Dual port one-way ${netport} ${owNum}thread:" >> $LOG_DIR/$IPERFDIR/Ipv6_data_integration.log
        sleep 1
        cat $LOG_DIR/$IPERFDIR/Ipv6_dual_one-way_local_${netport}_${owNum}thread.log | tail -1 >> $LOG_DIR/$IPERFDIR/Ipv6_data_integration.log
        cat $LOG_DIR/$IPERFDIR/Ipv6_dual_one-way_remote_${netport}_${owNum}thread.log | tail -1 >> $LOG_DIR/$IPERFDIR/Ipv6_data_integration.log
        echo -e "\n" >> $LOG_DIR/$IPERFDIR/Ipv6_data_integration.log
        sleep 1
    else
        echo "Dual port two-way ${twNum}thread:" >> $LOG_DIR/$IPERFDIR/Ipv6_data_integration.log
        sleep 1
        cat $LOG_DIR/$IPERFDIR/Ipv6_dual_twoway_local_${NETPORT1}_${twNum}thread.log | tail -1 >> $LOG_DIR/$IPERFDIR/Ipv6_data_integration.log
        cat $LOG_DIR/$IPERFDIR/Ipv6_dual_twoway_remote_${NETPORT1}_${twNum}thread.log | tail -1 >> $LOG_DIR/$IPERFDIR/Ipv6_data_integration.log
        cat $LOG_DIR/$IPERFDIR/Ipv6_dual_twoway_local_${NETPORT2}_${twNum}thread.log | tail -1 >> $LOG_DIR/$IPERFDIR/Ipv6_data_integration.log
        cat $LOG_DIR/$IPERFDIR/Ipv6_dual_twoway_remote_${NETPORT2}_${twNum}thread.log | tail -1 >> $LOG_DIR/$IPERFDIR/Ipv6_data_integration.log
        echo -e "\n" >> $LOG_DIR/$IPERFDIR/Ipv6_data_integration.log
        sleep 1    
    fi  
}

function ipv6_iperf_single()
{ 
    if [ $Ipv6Single -eq 1 ];then
        #MESSAGE="PASS"
        return 0
    fi
    MESSAGE="PASS"

    REMOTE1_IPV6_IP=$(ssh root@$BACK_IP "ifconfig ${NETPORT1} | grep 'inet6 addr:' | awk '{print \$3}' | awk -F'/' '{print \$1}' | head -n 1")
    REMOTE2_IPV6_IP=$(ssh root@$BACK_IP "ifconfig ${NETPORT2} | grep 'inet6 addr:' | awk '{print \$3}' | awk -F'/' '{print \$1}' | head -n 1")
    process="iperf"
    
    echo "#############################"
    echo "Run iperf Single port One-way..."
    echo "#############################"    
    SendPyte="SingleOne"
    echo 'iperf -s is down'
    #ssh root@$BACK_IP "killall iperf;iperf -s -V >/dev/null 2>&1 &"
    iperf_killer
    sleep 10
    #for owNum in $THREAD
     # do
    
        #iperf -c ${REMOTE2_IPV6_IP}%${LOCALPORT2} -V -t $IPERFDURATION -i 1 -P 1
        #echo "ff"
      #done
#iperf -c ${REMOTE2_IPV6_IP}%${LOCALPORT2} -V -t $IPERFDURATION -i 1 -P 5
#iperf -c ${REMOTE2_IPV6_IP}%${LOCALPORT2} -V -t $IPERFDURATION -i 1 -P 10

    for netport in $NETPORTLIST
    do
        if [ ${netport} == ${NETPORT1} ];then
            for owNum in $THREAD
            do
              remote_iperf_s
                echo "Run single port $netport ${owNum}thread......"
                iperf -c ${REMOTE1_IPV6_IP}%${LOCALPORT1} -V -t $IPERFDURATION -i 2 -P $owNum > $LOG_DIR/$IPERFDIR/Ipv6_single_one-way_${netport}_${owNum}thread.log  &
                check_single_process
                ipv6_data_integration
                iperf_killer
            done
            sleep 5
        fi
    done
    
    owNum=1
    remote_iperf_s
    iperf -c ${REMOTE2_IPV6_IP}%${LOCALPORT2} -V -t $IPERFDURATION -i 1 -P $owNum > $LOG_DIR/$IPERFDIR/Ipv6_single_one-way_${LOCALPORT2}_${owNum}thread.log &
    check_single_process
    ipv6_data_integration
    iperf_killer

    owNum=5
    remote_iperf_s
    iperf -c ${REMOTE2_IPV6_IP}%${LOCALPORT2} -V -t $IPERFDURATION -i 1 -P $owNum > $LOG_DIR/$IPERFDIR/Ipv6_single_one-way_${LOCALPORT2}_${owNum}thread.log &
    check_single_process
    ipv6_data_integration
    iperf_killer

    owNum=10
    remote_iperf_s
    iperf -c ${REMOTE2_IPV6_IP}%${LOCALPORT2} -V -t $IPERFDURATION -i 1 -P $owNum > $LOG_DIR/$IPERFDIR/Ipv6_single_one-way_${LOCALPORT2}_${owNum}thread.log &
    check_single_process
    ipv6_data_integration
    iperf_killer
    sleep 5

    #two-way perfornamce
  #if [ 'fefe' = 'fefe'  ];then
    #ssh root@$BACK_IP "killall iperf;sleep 10;iperf -s -V >/dev/null 2>&1 &"
    iperf_killer

    ssh root@$BACK_IP "ps -ef | grep iperf "
    echo "#############################"
    echo "Run iperf Single port two-way..."
    echo "#############################"
    SendPyte="SingleTwo"
    for twNum in $THREAD
    do
        remote_iperf_s
        ssh root@$BACK_IP "ps -ef | grep iperf "

        echo "Run single port two-way ${twNum}thread......"
        iperf -c ${REMOTE1_IPV6_IP}%${LOCALPORT1} -V -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/Ipv6_Single_two-way_${NETPORT1}_${twNum}thread.log &
        iperf -c ${REMOTE2_IPV6_IP}%${LOCALPORT2} -V -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/Ipv6_Single_two-way_${NETPORT2}_${twNum}thread.log &
        sleep 25
        check_single_process
        ipv6_data_integration
        iperf_killer
    done
  #fi
    Ipv6Single=1
   # MESSAGE="PASS"
    return 0
}

function ipv6_iperf_dual()
{
    if [ $Ipv6Dual -eq 1 ];then
       # MESSAGE="PASS"
        return 0
    fi
    MESSAGE="PASS"

    LOCAL1_IPV6_IP=$(ifconfig ${LOCALPORT1} | grep 'inet6 addr:' | awk '{print $3}' | awk -F'/' '{print $1}' | head -n 1)
    LOCAL2_IPV6_IP=$(ifconfig ${LOCALPORT2} | grep 'inet6 addr:' | awk '{print $3}' | awk -F'/' '{print $1}' | head -n 1)
    REMOTE1_IPV6_IP=$(ssh root@$BACK_IP "ifconfig ${NETPORT1} | grep 'inet6 addr:' | awk '{print \$3}' | awk -F'/' '{print \$1}' | head -n 1")
    REMOTE2_IPV6_IP=$(ssh root@$BACK_IP "ifconfig ${NETPORT2} | grep 'inet6 addr:' | awk '{print \$3}' | awk -F'/' '{print \$1}' | head -n 1")
    process="iperf"
    iperf_killer
    iperf -s -V >/dev/null 2>&1 &
    ssh root@$BACK_IP "iperf -s -V >/dev/null 2>&1 &"
    sleep 5
    echo "#############################"
    echo "Run iperf Dual port one-way..."
    echo "#############################"
    SendPyte="DualOne"
    for netport in $NETPORTLIST
    do
        if [ ${netport} == ${NETPORT1} ];then
            for owNum in $THREAD
            do
               iperf -s -V >/dev/null 2>&1 &
               ssh root@$BACK_IP "iperf -s -V >/dev/null 2>&1 &"
               sleep 5
   
                echo "Run dual port ${netport} ${owNum}thread......"
                iperf -c ${REMOTE1_IPV6_IP}%${LOCALPORT1} -V -t $IPERFDURATION -i 2 -P ${owNum} > $LOG_DIR/$IPERFDIR/Ipv6_dual_one-way_local_${netport}_${owNum}thread.log &
                ssh root@$BACK_IP "iperf -c ${LOCAL1_IPV6_IP}%${NETPORT1} -V -t $IPERFDURATION -i 2 -P ${owNum} > $LOG_DIR/$IPERFDIR/Ipv6_dual_one-way_remote_${netport}_${owNum}thread.log &"
                sleep $IPERFDURATION
                check_dual_process
                ipv6_data_integration
                iperf_killer
            done
            sleep 5
        else
            for owNum in $THREAD
            do
                iperf -s -V >/dev/null 2>&1 &
                ssh root@$BACK_IP "iperf -s -V >/dev/null 2>&1 &"
                sleep 5
   
                echo "Run dual port $netport ${owNum}thread......"
                iperf -c ${REMOTE2_IPV6_IP}%${LOCALPORT2} -V -t $IPERFDURATION -i 2 -P $owNum > $LOG_DIR/$IPERFDIR/Ipv6_dual_one-way_local_${netport}_${owNum}thread.log &
                ssh root@$BACK_IP "iperf -c ${LOCAL2_IPV6_IP}%${NETPORT2} -V -t $IPERFDURATION -i 2 -P $owNum > $LOG_DIR/$IPERFDIR/Ipv6_dual_one-way_remote_${netport}_${owNum}thread.log &"
                sleep $IPERFDURATION
                check_dual_process
                ipv6_data_integration
                iperf_killer
            done
            sleep 5
        fi
    done
    sleep 5

    echo "#############################"
    echo "Run iperf Dual port two-way..."
    echo "#############################"
    SendPyte="DualTwo"
    iperf_killer
    #iperf -s -V >/dev/null 2>&1 &
    #ssh root@$BACK_IP "killall iperf;iperf -s -V >/dev/null 2>&1 &"
    #sleep 5
    for twNum in $THREAD
    do
       iperf -s -V >/dev/null 2>&1 &
       ssh root@$BACK_IP "iperf -s -V >/dev/null 2>&1 &"
       sleep 5
   
        echo "Run Two-way ${twNum}thread......"
        iperf -c ${REMOTE1_IPV6_IP}%${LOCALPORT1} -V -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/Ipv6_dual_twoway_local_${NETPORT1}_${twNum}thread.log &
        iperf -c ${REMOTE2_IPV6_IP}%${LOCALPORT2} -V -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/Ipv6_dual_twoway_local_${NETPORT2}_${twNum}thread.log &
        ssh root@$BACK_IP "iperf -c ${LOCAL1_IPV6_IP}%${NETPORT1} -V -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/Ipv6_dual_two-way_remote_${NETPORT1}_${twNum}thread.log &"
        ssh root@$BACK_IP "iperf -c ${LOCAL2_IPV6_IP}%${NETPORT2} -V -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/Ipv6_dual_two-way_remote_${NETPORT2}_${twNum}thread.log &"
        sleep $IPERFDURATION
        check_dual_process
        ipv6_data_integration
        iperf_killer
    done
    Ipv6Dual=1
    #MESSAGE="PASS"
    return 0
}

function iperf_single()
{
    if [ $Ipv4Single -eq 1 ];then
       # MESSAGE="PASS"
        return 0
    fi
    MESSAGE="PASS"

    process="iperf"
    #killall iperf
    #ssh root@$BACK_IP "killall iperf;iperf -s >/dev/null 2>&1 &"
    #sleep 5
    iperf_killer
    echo "#############################"
    echo "Run iperf Single port One-way..."
    echo "#############################"    
    SendPyte="SingleOne"

    for netport in $NETPORTLIST
    do
        if [ ${netport} == ${NETPORT1} ];then
            for owNum in $THREAD
            do
               ssh root@$BACK_IP "killall iperf;iperf -s >/dev/null 2>&1 &"
               sleep 5

                echo "Run single port $netport ${owNum}thread......"
                iperf -c ${NETIP1} -t $IPERFDURATION -i 2 -P $owNum > $LOG_DIR/$IPERFDIR/single_one-way_${netport}_${owNum}thread.log &
                check_single_process
                data_integration
                iperf_killer
            done
            sleep 5
        else
            for owNum in $THREAD
            do
                ssh root@$BACK_IP "killall iperf;iperf -s >/dev/null 2>&1 &"
                sleep 5

                echo "Run single port $netport ${owNum}thread......"
                iperf -c ${NETIP2} -t $IPERFDURATION -i 1 -P $owNum > $LOG_DIR/$IPERFDIR/single_one-way_${netport}_${owNum}thread.log &
                check_single_process
                data_integration
                iperf_killer
            done
            sleep 5
        fi
    done
    sleep 5
    #two-way perfornamce
      #ssh root@$BACK_IP "killall iperf;iperf -s >/dev/null 2>&1 &"
      sleep 5
      iperf_killer
      echo "#############################"
      echo "Run iperf Single port two-way..."
      echo "#############################"
      SendPyte="SingleTwo"
      for twNum in $THREAD
      do
         ssh root@$BACK_IP "killall iperf;iperf -s >/dev/null 2>&1 &"
         sleep 5

        echo "Run single port two-way ${twNum}thread......"
        iperf -c ${NETIP1} -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/Single_two-way_${NETPORT1}_${twNum}thread.log &
        iperf -c ${NETIP2} -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/Single_two-way_${NETPORT2}_${twNum}thread.log &
        sleep 25
        check_single_process
        data_integration
        iperf_killer
      done
    Ipv4Single=1
    #MESSAGE="PASS"
    return 0 
}

function iperf_dual()
{
    if [ $Ipv4Dual -eq 1 ];then
       # MESSAGE="PASS"
        return 0
    fi
    MESSAGE="PASS"

    process="iperf"
    #killall iperf
    #iperf -s >/dev/null 2>&1 &
    #ssh root@$BACK_IP "killall iperf;iperf -s >/dev/null 2>&1 &"
    iperf_killer
    sleep 5
    echo "#############################"
    echo "Run iperf Dual port one-way..."
    echo "#############################"
    SendPyte="DualOne"
    for netport in $NETPORTLIST
    do
        if [ ${netport} == ${NETPORT1} ];then
            for owNum in $THREAD
            do
                iperf -s >/dev/null 2>&1 &
                ssh root@$BACK_IP "iperf -s >/dev/null 2>&1 &"
                sleep 5

                echo "Run dual port ${netport} ${owNum}thread......"
                iperf -c ${NETIP1} -t $IPERFDURATION -i 2 -P ${owNum} > $LOG_DIR/$IPERFDIR/dual_one-way_local_${netport}_${owNum}thread.log &
                ssh root@$BACK_IP "iperf -c ${LOCALIP1} -t $IPERFDURATION -i 2 -P ${owNum} > $LOG_DIR/$IPERFDIR/dual_one-way_remote_${netport}_${owNum}thread.log &"
                sleep $IPERFDURATION
                check_dual_process
                data_integration
                iperf_killer
            done
            sleep 5
        else
            for owNum in $THREAD
            do
                iperf -s >/dev/null 2>&1 &
                ssh root@$BACK_IP "iperf -s >/dev/null 2>&1 &"
                sleep 5


                echo "Run dual port $netport ${owNum}thread......"
                iperf -c ${NETIP2} -t $IPERFDURATION -i 2 -P $owNum > $LOG_DIR/$IPERFDIR/dual_one-way_local_${netport}_${owNum}thread.log &
                ssh root@$BACK_IP "iperf -c ${LOCALIP2} -t $IPERFDURATION -i 2 -P $owNum > $LOG_DIR/$IPERFDIR/dual_one-way_remote_${netport}_${owNum}thread.log &"
                sleep $IPERFDURATION
                check_dual_process
                data_integration
                iperf_killer
            done
            sleep 5
        fi
    done
    sleep 5

    echo "#############################"
    echo "Run iperf Dual port two-way..."
    echo "#############################"
    SendPyte="DualTwo"
    #killall iperf
    #iperf -s >/dev/null 2>&1 &
    #ssh root@$BACK_IP "killall iperf;iperf -s >/dev/null 2>&1 &"
    #sleep 5
    iperf_killer
    for twNum in $THREAD
    do
        iperf -s >/dev/null 2>&1 &
        ssh root@$BACK_IP "iperf -s >/dev/null 2>&1 &"
        sleep 5

        echo "Run Two-way ${twNum}thread......"
        iperf -c ${NETIP1} -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/dual_twoway_local_${NETPORT1}_${twNum}thread.log &
        iperf -c ${NETIP2} -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/dual_twoway_local_${NETPORT2}_${twNum}thread.log &
        ssh root@$BACK_IP "iperf -c ${LOCALIP1} -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/dual_twoway_remote_${NETPORT1}_${twNum}thread.log &"
        ssh root@$BACK_IP "iperf -c ${LOCALIP2} -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/dual_twoway_remote_${NETPORT2}_${twNum}thread.log &"
        sleep $IPERFDURATION
        check_dual_process
        data_integration
        iperf_killer
    done
    Ipv4Dual=1
    #MESSAGE="PASS"
    return 0 
}


function Vlan_iperf_single()
{
    if [ $VlanSingle -eq 1 ];then
        MESSAGE="PASS"
        return 0
    fi
    MESSAGE="PASS"

    ip link add link $LOCALPORT1 name $LOCALPORT1.401 type vlan id 401
    ip link add link $LOCALPORT2 name $LOCALPORT2.400 type vlan id 400
    ifconfig $LOCALPORT1.401 ${vlan_local1_ip};ifconfig $LOCALPORT2.400 ${vlan_local2_ip}
    sleep 5
    
    ssh root@$BACK_IP "
    ip link add link $NETPORT1 name $NETPORT1.401 type vlan id 401;\
    ip link add link $NETPORT2 name $NETPORT2.400 type vlan id 400;\
    ifconfig $NETPORT1.401 ${vlan_remote1_ip};ifconfig $NETPORT2.400 ${vlan_remote2_ip};\
    sleep 5"
    
    process="iperf"
    #ssh root@$BACK_IP "iperf -s >/dev/null 2>&1 &"
    #killall iperf
    #iperf -s >/dev/null 2>&1 &
    iperf_killer
   # ssh root@$BACK_IP "killall iperf;iperf -s >/dev/null 2>&1 &"
   # sleep 5
    echo "#############################"
    echo "Run iperf Single port One-way..."
    echo "#############################"    
    SendPyte="SingleOne"

    for netport in $NETPORTLIST
    do
        if [ ${netport} == ${NETPORT1} ];then
            for owNum in $THREAD
            do
                ssh root@$BACK_IP "iperf -s >/dev/null 2>&1 &"
                sleep 5
   
                echo "Run single port $netport ${owNum}thread......"
                echo "$LOG_DIR/$IPERFDIR/Vlan_single_one-way_${netport}_${owNum}thread.log"
                iperf -c ${vlan_remote1_ip} -t $IPERFDURATION -i 2 -P $owNum > $LOG_DIR/$IPERFDIR/Vlan_single_one-way_${netport}_${owNum}thread.log &
                cat $LOG_DIR/$IPERFDIR/Vlan_single_one-way_${netport}_${owNum}thread.log 
                sleep 25
                check_single_process
                iperf_killer
                sleep 5
            done
            sleep 5
        else
            for owNum in $THREAD
            do
                ssh root@$BACK_IP "iperf -s >/dev/null 2>&1 &"
                sleep 5
   

                ssh root@$BACK_IP "killall iperf;iperf -s >/dev/null 2>&1 &"
                sleep 5
                echo "Run single port $netport ${owNum}thread......"
                iperf -c ${vlan_remote2_ip} -t $IPERFDURATION -i 1 -P $owNum > $LOG_DIR/$IPERFDIR/Vlan_single_one-way_${netport}_${owNum}thread.log &
                sleep 25
                check_single_process
                iperf_killer
                sleep 10
            done
            sleep 5
        fi
    done
    sleep 5

    #two-way perfornamce
    iperf_killer
    #ssh root@$BACK_IP "killall iperf;iperf -s -V >/dev/null 2>&1 &"
    echo "#############################"
    echo "Run iperf Single port two-way..."
    echo "#############################"
    SendPyte="SingleTwo"
    for twNum in $THREAD
    do
        ssh root@$BACK_IP "iperf -s >/dev/null 2>&1 &"
        sleep 5
   

        echo "Run single port two-way ${twNum}thread......"
        iperf -c ${vlan_remote1_ip} -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/Vlan_Single_two-way_${NETPORT1}_${twNum}thread.log &
        iperf -c ${vlan_remote2_ip} -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/Vlan_Single_two-way_${NETPORT2}_${twNum}thread.log &
        sleep 25
        check_single_process
        iperf_killer
    done
   
   # VlanSingle=1
    
    vconfig rem $NETPORT1.401
    vconfig rem $NETPORT2.400
    ssh root@${BACK_IP} "vconfig rem $NETPORT1.401;vconfig rem $NETPORT2.400"

    VlanSingle=1

}

function Vlan_iperf_dual()
{
    if [ $VlanDual -eq 1 ];then
        MESSAGE="PASS"
        return 0
    fi
    MESSAGE="PASS"

    ip link add link $LOCALPORT1 name $LOCALPORT1.401 type vlan id 401
    ip link add link $LOCALPORT2 name $LOCALPORT2.400 type vlan id 400
    ifconfig $LOCALPORT1.401 ${vlan_local1_ip};ifconfig $LOCALPORT2.400 ${vlan_local2_ip}
    sleep 5
    
    ssh root@$BACK_IP "
    ip link add link $NETPORT1 name $NETPORT1.401 type vlan id 401;\
    ip link add link $NETPORT2 name $NETPORT2.400 type vlan id 400;\
    ifconfig $NETPORT1.401 ${vlan_remote1_ip};ifconfig $NETPORT2.400 ${vlan_remote2_ip};\
    sleep 5"
    
    process="iperf"
    #killall iperf
    iperf_killer
    #iperf -s >/dev/null 2>&1 &
    #ssh root@$BACK_IP "killall iperf;iperf -s -V >/dev/null 2>&1 &"
    #sleep 5
    echo "#############################"
    echo "Run iperf Dual port one-way..."
    echo "#############################"
    SendPyte="DualOne"
    for netport in $NETPORTLIST
    do
        if [ ${netport} == ${NETPORT1} ];then
            for owNum in $THREAD
            do
                iperf -s >/dev/null 2>&1 &
                ssh root@$BACK_IP "iperf -s -V >/dev/null 2>&1 &"
                sleep 5
   
                echo "Run dual port ${netport} ${owNum}thread......"
                iperf -c ${vlan_remote1_ip} -t $IPERFDURATION -i 2 -P ${owNum} > $LOG_DIR/$IPERFDIR/Vlan_dual_one-way_local_${netport}_${owNum}thread.log &
                ssh root@$BACK_IP "mkdir -p $LOG_DIR/$IPERFDIR;iperf -c ${vlan_local1_ip} -t $IPERFDURATION -i 2 -P ${owNum} > /$LOG_DIR/$IPERFDIR/Vlan_dual_one-way_remote_${netport}_${owNum}thread.log &"
                sleep $IPERFDURATION
                check_dual_process
                iperf_killer
            done
            sleep 5
        else
            for owNum in $THREAD
            do
                iperf -s >/dev/null 2>&1 &
                ssh root@$BACK_IP "iperf -s -V >/dev/null 2>&1 &"
                sleep 5
   

                echo "Run dual port $netport ${owNum}thread......"
                iperf -c ${vlan_remote2_ip} -t $IPERFDURATION -i 2 -P $owNum > $LOG_DIR/$IPERFDIR/Vlan_dual_one-way_local_${netport}_${owNum}thread.log &
                ssh root@$BACK_IP "iperf -c ${vlan_local2_ip} -t $IPERFDURATION -i 2 -P $owNum > /$LOG_DIR/$IPERFDIR/Vlan_dual_one-way_remote_${netport}_${owNum}thread.log &"
                sleep $IPERFDURATION
                check_dual_process
                iperf_killer
            done
            sleep 5
        fi
    done
    sleep 5

    echo "#############################"
    echo "Run iperf Dual port two-way..."
    echo "#############################"
    SendPyte="DualTwo"
    #killall iperf
    #iperf -s >/dev/null 2>&1 &
    #ssh root@$BACK_IP "killall iperf;iperf -s >/dev/null 2>&1 &"
    for twNum in $THREAD
    do
                iperf -s >/dev/null 2>&1 &
                ssh root@$BACK_IP "iperf -s -V >/dev/null 2>&1 &"
                sleep 5
   

        echo "Run Two-way ${twNum}thread......"
        iperf -c ${vlan_remote1_ip} -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/Vlan_dual_twoway_local_${NETPORT1}_${twNum}thread.log &
        iperf -c ${vlan_remote2_ip} -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/Vlan_dual_twoway_local_${NETPORT2}_${twNum}thread.log &
        ssh root@$BACK_IP "iperf -c ${vlan_local1_ip} -t $IPERFDURATION -i 2 -P $twNum > /$LOG_DIR/$IPERFDIR/Vlan_dual_two-way_remote_${NETPORT1}_${twNum}thread.log &"
        ssh root@$BACK_IP "iperf -c ${vlan_local2_ip} -t $IPERFDURATION -i 2 -P $twNum > /$LOG_DIR/$IPERFDIR/Vlan_dual_two-way_remote_${NETPORT2}_${twNum}thread.log &"
        sleep $IPERFDURATION
        check_dual_process
        iperf_killer
    done
    
    vconfig rem $NETPORT1.401
    vconfig rem $NETPORT2.400
    ssh root@${BACK_IP} "vconfig rem $NETPORT1.401;vconfig rem $NETPORT2.400"
    VlanDual=1
}


function netperf_single()
{
    if [ $NetperfSingle -eq 1 ];then
        #MESSAGE="PASS"
        return 0
    fi
    MESSAGE="PASS"

    echo "#############################"
    echo "Run netperf Single port TCP/UDP STREAM..."
    echo "#############################"
    process="netperf"
    ssh root@$BACK_IP "killall netserver;netserver >/dev/null 2>&1 &"
    for netport in ${NETPORTLIST}
    do
        if [ ${netport} == ${NETPORT1} ];then
            for tcpnum in ${TCP_MSS}
            do
                echo "Run Single port $netport TCP_STREAM $tcpnum Message Size(bytes)..."
                netperf -H ${NETIP1} -l ${NETPERFDURATION} -t TCP_STREAM -- -m ${tcpnum} >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_TCP_STREAM.log
                check_single_process
                echo -e "\n" >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_TCP_STREAM.log
                
                echo "Run Single port $netport TCP_RR $tcpnum Message Size(bytes)..."
                netperf -H ${NETIP1} -l ${NETPERFDURATION} -t TCP_RR -- -r ${tcpnum} >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_TCP_RR.log
                check_single_process
                echo -e "\n" >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_TCP_RR.log
                
                echo "Run Single port $netport TCP_CRR $tcpnum Message Size(bytes)..."
                netperf -H ${NETIP1} -l ${NETPERFDURATION} -t TCP_CRR -- -r ${tcpnum} >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_TCP_CRR.log
                check_single_process
                echo -e "\n" >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_TCP_CRR.log
            done

            for udpnum in ${UDP_MSS}
            do
                echo "Run Single port $netport UDP_STREAM $udpnum Message Size(bytes)..."
                netperf -H ${NETIP1} -l ${NETPERFDURATION} -t UDP_STREAM -- -m ${udpnum} >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_UDP_STREAM.log
                check_single_process
                echo -e "\n" >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_UDP_STREAM.log
                
                echo "Run Single port $netport UDP_RR $udpnum Message Size(bytes)..."
                netperf -H ${NETIP1} -l ${NETPERFDURATION} -t UDP_RR -- -r ${udpnum} >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_UDP_RR.log
                check_single_process
                echo -e "\n" >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_UDP_RR.log
            done
        else
            for tcpnum in ${TCP_MSS}
            do
                echo "Run Single port $netport TCP_STREAM $tcpnum Message Size(bytes)..."
                netperf -H ${NETIP2} -l ${NETPERFDURATION} -t TCP_STREAM -- -m ${tcpnum} >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_TCP_STREAM.log
                check_single_process
                echo -e "\n" >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_TCP_STREAM.log
                
                echo "Run Single port $netport TCP_RR $tcpnum Message Size(bytes)..."
                netperf -H ${NETIP2} -l ${NETPERFDURATION} -t TCP_RR -- -r ${tcpnum} >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_TCP_RR.log
                check_single_process
                echo -e "\n" >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_TCP_RR.log
                
                echo "Run Single port $netport TCP_CRR $tcpnum Message Size(bytes)..."
                netperf -H ${NETIP2} -l ${NETPERFDURATION} -t TCP_CRR -- -r ${tcpnum} >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_TCP_CRR.log
                check_single_process
                echo -e "\n" >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_TCP_CRR.log
            done

            for udpnum in ${UDP_MSS}
            do
                echo "Run Single port $netport UDP_STREAM $udpnum Message Size(bytes)..."
                netperf -H ${NETIP2} -l ${NETPERFDURATION} -t UDP_STREAM -- -m ${udpnum} >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_UDP_STREAM.log
                check_single_process
                echo -e "\n" >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_UDP_STREAM.log
                
                echo "Run Single port $netport UDP_RR $udpnum Message Size(bytes)..."
                netperf -H ${NETIP2} -l ${NETPERFDURATION} -t UDP_RR -- -r ${udpnum} >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_UDP_RR.log
                check_single_process
                echo -e "\n" >> $LOG_DIR/$NETPERFDIR/Single_port_${netport}_UDP_RR.log
            done
        fi
    done
    NetperfSingle=1
    #MESSAGE="PASS"
    return 0
}

function netperf_dual
{
    if [ $NetperfDual -eq 1 ];then
        #MESSAGE="PASS"
        return 0
    fi
    MESSAGE="PASS"

    echo "#############################"
    echo "Run netperf dual port TCP/UDP Message..."
    echo "#############################"
    process="netperf"
    ssh root@$BACK_IP "killall netserver;netserver >/dev/null 2>&1 &"

    for tcpnum in ${TCP_MSS}
    do
        echo "Run dual port TCP_STREAM $tcpnum Message Size(bytes)..."
        netperf -H ${NETIP1} -l ${NETPERFDURATION} -t TCP_STREAM -- -m ${tcpnum} >> $LOG_DIR/$NETPERFDIR/Dual_port_TCP_STREAM.log &
        netperf -H ${NETIP2} -l ${NETPERFDURATION} -t TCP_STREAM -- -m ${tcpnum} >> $LOG_DIR/$NETPERFDIR/Dual_port_TCP_STREAM.log &
        sleep ${NETPERFDURATION}
        check_single_process
        echo -e "\n" >> $LOG_DIR/$NETPERFDIR/Dual_port_TCP_STREAM.log
        
        echo "Run dual port TCP_RR $tcpnum Message Size(bytes)..."
        netperf -H ${NETIP1} -l ${NETPERFDURATION} -t TCP_RR -- -r ${tcpnum} >> $LOG_DIR/$NETPERFDIR/Dual_port_TCP_RR.log &
        netperf -H ${NETIP2} -l ${NETPERFDURATION} -t TCP_RR -- -r ${tcpnum} >> $LOG_DIR/$NETPERFDIR/Dual_port_TCP_RR.log &
        sleep ${NETPERFDURATION}
        check_single_process
        echo -e "\n" >> $LOG_DIR/$NETPERFDIR/Dual_port_TCP_RR.log
        
        echo "Run dual port TCP_CRR $tcpnum Message Size(bytes)..."
        netperf -H ${NETIP1} -l ${NETPERFDURATION} -t TCP_CRR -- -r ${tcpnum} >> $LOG_DIR/$NETPERFDIR/Dual_port_TCP_CRR.log &
        netperf -H ${NETIP2} -l ${NETPERFDURATION} -t TCP_CRR -- -r ${tcpnum} >> $LOG_DIR/$NETPERFDIR/Dual_port_TCP_CRR.log &
        sleep ${NETPERFDURATION}
        check_single_process
        echo -e "\n" >> $LOG_DIR/$NETPERFDIR/Dual_port_TCP_CRR.log
    done
    
    for udpnum in ${UDP_MSS}
    do
        echo "Run dual port UDP_STREAM $udpnum Message Size(bytes)..."
        netperf -H ${NETIP1} -l ${NETPERFDURATION} -t UDP_STREAM -- -m ${udpnum} >> $LOG_DIR/$NETPERFDIR/Dual_port_UDP_STREAM.log &
        netperf -H ${NETIP2} -l ${NETPERFDURATION} -t UDP_STREAM -- -m ${udpnum} >> $LOG_DIR/$NETPERFDIR/Dual_port_UDP_STREAM.log &
        sleep ${NETPERFDURATION}
        check_single_process
        echo -e "\n" >> $LOG_DIR/$NETPERFDIR/Dual_port_UDP_STREAM.log
        
        echo "Run dual port UDP_RR $udpnum Message Size(bytes)..."
        netperf -H ${NETIP1} -l ${NETPERFDURATION} -t UDP_RR -- -r ${udpnum} >> $LOG_DIR/$NETPERFDIR/Dual_port_UDP_RR.log &
        netperf -H ${NETIP2} -l ${NETPERFDURATION} -t UDP_RR -- -r ${udpnum} >> $LOG_DIR/$NETPERFDIR/Dual_port_UDP_RR.log &
        sleep ${NETPERFDURATION}
        check_single_process
        echo -e "\n" >> $LOG_DIR/$NETPERFDIR/Dual_port_UDP_RR.log
    done
    NetperfDual=1
    #MESSAGE="PASS"
    return 0 
}


function qperf_test()
{
    if [ $QperfTest -eq 1 ];then
        #MESSAGE="PASS"
        return 0
    fi
    MESSAGE="PASS"

    echo "#############################"
    echo "Run qperf test..."
    echo "#############################"
    process="qperf"
    ssh root@$BACK_IP "killall qperf;qperf >/dev/null 2>&1 &"
    for netport in ${NETPORTLIST}
    do
        if [ ${netport} == ${NETPORT1} ];then
            echo "Run Single port $netport qperf TCP..."
            qperf ${NETIP1} -oo msg_size:1:64K:*2 -vu tcp_lat tcp_bw >> $LOG_DIR/$QPERFDIR/Single_port_${netport}_tcp.log
            check_single_process
            
            echo "Run Single port $netport qperf UCP..."
            qperf ${NETIP1} -oo msg_size:1:64K:*2 -vu udp_lat udp_bw >> $LOG_DIR/$QPERFDIR/Single_port_${netport}_udp.log
            check_single_process
        else
            echo "Run Single port $netport qperf TCP..."
            qperf ${NETIP2} -oo msg_size:1:64K:*2 -vu tcp_lat tcp_bw >> $LOG_DIR/$QPERFDIR/Single_port_${netport}_tcp.log
            check_single_process
            
            echo "Run Single port $netport qperf UCP..."
            qperf ${NETIP2} -oo msg_size:1:64K:*2 -vu udp_lat udp_bw >> $LOG_DIR/$QPERFDIR/Single_port_${netport}_udp.log
            check_single_process
        fi
    done
    QperfTest=1
    #MESSAGE="PASS"
    return 0 
}

function Vlan_iperf_single()
{
    if [ $VlanSingle -eq 1 ];then
        MESSAGE="PASS"
        return 0
    fi
    MESSAGE="PASS"

    ip link add link $LOCALPORT1 name $LOCALPORT1.401 type vlan id 401
    ip link add link $LOCALPORT2 name $LOCALPORT2.400 type vlan id 400
    ifconfig $LOCALPORT1.401 ${vlan_local1_ip};ifconfig $LOCALPORT2.400 ${vlan_local2_ip}
    sleep 5
    
    ssh root@$BACK_IP "
    ip link add link $NETPORT1 name $NETPORT1.401 type vlan id 401;\
    ip link add link $NETPORT2 name $NETPORT2.400 type vlan id 400;\
    ifconfig $NETPORT1.401 ${vlan_remote1_ip};ifconfig $NETPORT2.400 ${vlan_remote2_ip};\
    sleep 5"
    
    process="iperf"
    #ssh root@$BACK_IP "iperf -s >/dev/null 2>&1 &"
    #killall iperf
    #iperf -s >/dev/null 2>&1 &
    iperf_killer
   # ssh root@$BACK_IP "killall iperf;iperf -s >/dev/null 2>&1 &"
   # sleep 5
    echo "#############################"
    echo "Run iperf Single port One-way..."
    echo "#############################"    
    SendPyte="SingleOne"

    for netport in $NETPORTLIST
    do
        if [ ${netport} == ${NETPORT1} ];then
            for owNum in $THREAD
            do
                ssh root@$BACK_IP "iperf -s >/dev/null 2>&1 &"
                sleep 5
   
                echo "Run single port $netport ${owNum}thread......"
                echo "$LOG_DIR/$IPERFDIR/Vlan_single_one-way_${netport}_${owNum}thread.log"
                iperf -c ${vlan_remote1_ip} -t $IPERFDURATION -i 2 -P $owNum > $LOG_DIR/$IPERFDIR/Vlan_single_one-way_${netport}_${owNum}thread.log &
                cat $LOG_DIR/$IPERFDIR/Vlan_single_one-way_${netport}_${owNum}thread.log 
                sleep 25
                check_single_process
                iperf_killer
                sleep 5
            done
            sleep 5
        else
            for owNum in $THREAD
            do
                ssh root@$BACK_IP "iperf -s >/dev/null 2>&1 &"
                sleep 5
   

                ssh root@$BACK_IP "killall iperf;iperf -s >/dev/null 2>&1 &"
                sleep 5
                echo "Run single port $netport ${owNum}thread......"
                iperf -c ${vlan_remote2_ip} -t $IPERFDURATION -i 1 -P $owNum > $LOG_DIR/$IPERFDIR/Vlan_single_one-way_${netport}_${owNum}thread.log &
                sleep 25
                check_single_process
                iperf_killer
                sleep 10
            done
            sleep 5
        fi
    done
    sleep 5

    #two-way perfornamce
    iperf_killer
    #ssh root@$BACK_IP "killall iperf;iperf -s -V >/dev/null 2>&1 &"
    echo "#############################"
    echo "Run iperf Single port two-way..."
    echo "#############################"
    SendPyte="SingleTwo"
    for twNum in $THREAD
    do
        ssh root@$BACK_IP "iperf -s >/dev/null 2>&1 &"
        sleep 5
   

        echo "Run single port two-way ${twNum}thread......"
        iperf -c ${vlan_remote1_ip} -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/Vlan_Single_two-way_${NETPORT1}_${twNum}thread.log &
        iperf -c ${vlan_remote2_ip} -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/Vlan_Single_two-way_${NETPORT2}_${twNum}thread.log &
        sleep 25
        check_single_process
        iperf_killer
    done
   
   # VlanSingle=1
    
    vconfig rem $NETPORT1.401
    vconfig rem $NETPORT2.400
    ssh root@${BACK_IP} "vconfig rem $NETPORT1.401;vconfig rem $NETPORT2.400"

    VlanSingle=1

}

local_ip_1=""
local_ip_2=""
remote_ip_1=""
remote_ip_2=""

local_net_1=""
local_net_2=""
remote_net_1=""
remote_net_2=""

IPV6_MASK=""

#*******
#***func: prepare IP and network env for iperf test
#***input:
#         $1 : net port type (XGE,GE)
#         $2 : protocol type (VLAN,IPV6,IPV4)   
function iperf_env_prepare()
{
   
   case $2 in
		VLAN)
			if [ x"$1" = x"GE" ];then
				local_ip_1="${vlan_local1_ip}"
				local_ip_2="${vlan_local2_ip}"
				remote_ip_1="${vlan_remote1_ip}"
				remote_ip_2="${vlan_remote2_ip}"
						
				local_net_1="$local_tp1.401"
				local_net_2="$local_fibre1.400"
				remote_net_1="$remote_tp1.401"
				remote_net_2="$remote_fibre1.400"
						
				ip link add link $local_tp1 name $local_net_1 type vlan id 401
				ip link add link $local_fibre1 name $local_net_2 type vlan id 400
                		ifconfig $local_net_1 ${local_ip_1};ifconfig $local_net_2 ${local_ip_2}
				sleep 5
    
				ssh root@$BACK_IP "
				ip link add link $remote_tp1 name $remote_net_1 type vlan id 401;\
				ip link add link $remote_fibre1 name $remote_net_2 type vlan id 400;\
				ifconfig $remote_net_1 ${remote_ip_1};ifconfig $remote_net_2 ${remote_ip_2};\
				sleep 5"
			else
				local_ip_1="${vlan_local2_ip}"
				local_ip_2="${vlan_local1_ip}"
				remote_ip_1="${vlan_remote2_ip}"
				remote_ip_2="${vlan_remote1_ip}"
						
				local_net_1="$local_fibre1.400"
				local_net_2="$local_tp1.401"
				remote_net_1="$remote_fibre1.400"
				remote_net_2="$remote_tp1.401"
						
				ip link add link $local_fibre1 name $local_net_1 type vlan id 400
				ip link add link $local_tp1 name $local_net_2 type vlan id 401
                        	ifconfig $local_net_1 ${local_ip_1};ifconfig $local_net_2 ${local_ip_2}
				sleep 5
    
				ssh root@$BACK_IP "
				ip link add link $remote_fibre1 name $remote_net_1 type vlan id 400;\
				ip link add link $remote_tp1 name $remote_net_2 type vlan id 401;\
				ifconfig $remote_net_1 ${remote_ip_1};ifconfig $remote_net_2 ${remote_ip_2};\
				sleep 5"
			fi
			IPV6_MASK=""

		;;
		IPV6)
			if [ x"$1" = x"GE" ];then
				local_net_1="$local_tp1"
				local_net_2="$local_fibre1"
				remote_net_1="$remote_tp1"
				remote_net_2="$remote_fibre1"
						
				local_ip_1=$(ifconfig ${local_net_1} | grep 'inet6 addr:' | awk '{print $3}' | awk -F'/' '{print $1}' | head -n 1)
				local_ip_1="${local_ip_1}%${remote_net_1}"
				local_ip_2=$(ifconfig ${local_net_2} | grep 'inet6 addr:' | awk '{print $3}' | awk -F'/' '{print $1}' | head -n 1)
				local_ip_2="${local_ip_2}%${remote_net_2}"
				remote_ip_1=$(ssh root@$BACK_IP "ifconfig ${remote_net_1} | grep 'inet6 addr:' | awk '{print \$3}' | awk -F'/' '{print \$1}' | head -n 1")
				remote_ip_1="${remote_ip_1}%${local_net_1}"
				remote_ip_2=$(ssh root@$BACK_IP "ifconfig ${remote_net_2} | grep 'inet6 addr:' | awk '{print \$3}' | awk -F'/' '{print \$1}' | head -n 1")
				remote_ip_2="${remote_ip_2}%${local_net_2}"

			else
				local_net_1="$local_fibre1"
				local_net_2="$local_tp1"
				remote_net_1="$remote_fibre1"
				remote_net_2="$remote_tp1"
						
				local_ip_1=$(ifconfig ${local_net_1} | grep 'inet6 addr:' | awk '{print $3}' | awk -F'/' '{print $1}' | head -n 1)
				local_ip_1="${local_ip_1}%${remote_net_1}"
				local_ip_2=$(ifconfig ${local_net_2} | grep 'inet6 addr:' | awk '{print $3}' | awk -F'/' '{print $1}' | head -n 1)
				local_ip_2="${local_ip_2}%${remote_net_2}"
				remote_ip_1=$(ssh root@$BACK_IP "ifconfig ${remote_net_1} | grep 'inet6 addr:' | awk '{print \$3}' | awk -F'/' '{print \$1}' | head -n 1")
				remote_ip_1="${remote_ip_1}%${local_net_1}"
				remote_ip_2=$(ssh root@$BACK_IP "ifconfig ${remote_net_2} | grep 'inet6 addr:' | awk '{print \$3}' | awk -F'/' '{print \$1}' | head -n 1")
				remote_ip_2="${remote_ip_2}%${local_net_2}"

			fi
			IPV6_MASK="-V"
		;;
		IPV4)
			if [ x"$1" = x"GE" ];then
				local_ip_1="${local_tp1_ip}"
				local_ip_2="${local_fibre1_ip}"
				remote_ip_1="${remote_tp1_ip}"
				remote_ip_2="${remote_fibre1_ip}"
						
				local_net_1="$local_tp1"
				local_net_2="$local_fibre1"
				remote_net_1="$remote_tp1"
				remote_net_2="$remote_fibre1"
			else
				local_ip_1="${local_fibre1_ip}"
				local_ip_2="${local_tp1_ip}"
				remote_ip_1="${remote_fibre1_ip}"
				remote_ip_2="${remote_tp1_ip}"
						
				local_net_1="$local_fibre1"
				local_net_2="$local_tp1"
				remote_net_1="$remote_fibre1"
				remote_net_2="$remote_tp1"
			fi	
			IPV6_MASK=""
		
		;;
		*)
		;;
	esac
	
	
}

#*******
#***func: prepare IP and network env for iperf test
#***input:
#         $1 : net port type (XGE,GE)
#         $2 : protocol type (VLAN,IPV6,IPV4)   
function iperf_env_terminate()
{
	case $2 in
		VLAN)
			vconfig rem $local_net_1
			vconfig rem $local_net_2
			ssh root@${BACK_IP} "vconfig rem $remote_net_1;vconfig rem $remote_net_2"
		;;
		*)
		;;
	esac
}

#**function: iperf ,Board as custom , single port
function iperf_single1()
{
    MESSAGE="PASS"
	
    iperf_env_prepare ${PORT_TYPE} ${PROTOCOL_TYPE}
    
    process="iperf"

    iperf_killer

    echo "#############################"
    echo "Run iperf Single port One-way..."
    echo "#############################"    
    SendPyte="SingleOne"

    for owNum in $THREAD
	do
                ssh root@$BACK_IP "iperf -s ${IPV6_MASK}  >/dev/null 2>&1 &"
                sleep 5
   
                echo "Run ${PROTOCOL_TYPE} as customer single port $local_net_1 ${owNum}thread......"
                iperf -c ${remote_ip_1} ${IPV6_MASK} -t $IPERFDURATION -i 2 -P $owNum >  $LOG_DIR/$IPERFDIR/${PROTOCOL_TYPE}_single1_one-way_${local_net_1}_${owNum}thread.log &
                
                sleep 25
                check_single_process
                iperf_killer
                sleep 5
	done
    sleep 5

    iperf_killer
    
    iperf_env_terminate ${PORT_TYPE} ${PROTOCOL_TYPE}	

}

#**function: iperf ,Board as server , single port
function iperf_single2()
{

    MESSAGE="PASS"

    iperf_env_prepare ${PORT_TYPE} ${PROTOCOL_TYPE}
    
    process="iperf"

    iperf_killer

    echo "#############################"
    echo "Run iperf Single port One-way..."
    echo "#############################"    
    SendPyte="SingleOne"

	for owNum in $THREAD
	do
                
		iperf -s ${IPV6_MASK} >/dev/null 2>&1 &
                echo "Run ${PROTOCOL_TYPE} as server single port $local_net_1 ${owNum}thread......"
                
                ssh root@${BACK_IP} "mkdir -p $LOG_DIR/$IPERFDIR;iperf -c ${local_ip_1} ${IPV6_MASK} -t $IPERFDURATION -i 2 -P $owNum > /$LOG_DIR/$IPERFDIR/${PROTOCOL_TYPE}_single2_one-way_${local_net_1}_${owNum}thread.log &"
                
                sleep 25
                check_remote_single_process
                iperf_killer
                sleep 5
	done

    iperf_killer
    
    iperf_env_terminate ${PORT_TYPE} ${PROTOCOL_TYPE}


}

#**function: iperf ,Board as custom and server same time , single port
function iperf_single3()
{

    MESSAGE="PASS"

    iperf_env_prepare ${PORT_TYPE} ${PROTOCOL_TYPE}
    
    process="iperf"

    sleep 5

    #two-way perfornamce
    iperf_killer
    #ssh root@$BACK_IP "killall iperf;iperf -s -V >/dev/null 2>&1 &"
    echo "#############################"
    echo "Run iperf Single port two-way..."
    echo "#############################"
    SendPyte="SingleTwo"
    for twNum in $THREAD
    do
	iperf -s ${IPV6_MASK} >/dev/null 2>&1 &
        ssh root@$BACK_IP "iperf -s ${IPV6_MASK} >/dev/null 2>&1 &"
        sleep 5
   
        echo "Run ${PROTOCOL_TYPE} as server and custom single port ${local_net_1} two-way ${twNum}thread......"
        iperf -c ${remote_ip_1} ${IPV6_MASK} -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/${PROTOCOL_TYPE}_Single_two-way_${local_net_1}_${twNum}thread.log &
	ssh root@${BACK_IP} "mkdir -p $LOG_DIR/$IPERFDIR;iperf -c ${local_ip_1} ${IPV6_MASK} -t $IPERFDURATION -i 2 -P $owNum > /$LOG_DIR/$IPERFDIR/${PROTOCOL_TYPE}_single_one-way_${local_net_1}_${owNum}thread.log &"
        sleep 25
        check_dual_process
        iperf_killer
    done
    
    iperf_env_terminate ${PORT_TYPE} ${PROTOCOL_TYPE}
}

#**function: iperf ,Board as custom  , two port
function iperf_dual4()
{
    MESSAGE="PASS"

	iperf_env_prepare ${PORT_TYPE} ${PROTOCOL_TYPE}
    
    process="iperf"

    #two-way perfornamce
    iperf_killer
    
    echo "#############################"
    echo "Run iperf Single port two-way..."
    echo "#############################"
    SendPyte="SingleTwo"
    for twNum in $THREAD
    do
        ssh root@$BACK_IP "iperf -s ${IPV6_MASK} >/dev/null 2>&1 &"
        sleep 5

        echo "Run ${PROTOCOL_TYPE} as customer  dual port ${local_net_1} two-way ${twNum}thread......"
        iperf -c ${remote_ip_1} ${IPV6_MASK} -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/${PROTOCOL_TYPE}_Single_two-way_${local_net_1}_${twNum}thread.log &
        sleep 1
	echo ${remote_ip_2}
	iperf -c ${remote_ip_2} ${IPV6_MASK} -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/${PROTOCOL_TYPE}_Single_two-way_${local_net_1}_${twNum}thread.log &
        sleep 25
        check_single_process
        iperf_killer
    done
    
    iperf_env_terminate ${PORT_TYPE} ${PROTOCOL_TYPE}

}

#**function: iperf ,Board as server  , two port
function iperf_dual5()
{
    MESSAGE="PASS"

    iperf_env_prepare ${PORT_TYPE} ${PROTOCOL_TYPE}
    
    process="iperf"

    #two-way perfornamce
    iperf_killer
    
    echo "#############################"
    echo "Run iperf Single port two-way..."
    echo "#############################"
    SendPyte="SingleTwo"
    for twNum in $THREAD
    do
        iperf -s ${IPV6_MASK} >/dev/null 2>&1 &
        sleep 5

        echo "Run ${PROTOCOL_TYPE} as server  dual port two-way ${twNum}thread......"
        ssh root@$BACK_IP "iperf -c ${local_ip_1} ${IPV6_MASK} -t $IPERFDURATION -i 2 -P $twNum > /$LOG_DIR/$IPERFDIR/${PROTOCOL_TYPE}_Single_two-way_${local_net_1}_${twNum}thread.log &"
        ssh root@$BACK_IP "iperf -c ${local_ip_2} ${IPV6_MASK} -t $IPERFDURATION -i 2 -P $twNum > /$LOG_DIR/$IPERFDIR/${PROTOCOL_TYPE}_Single_two-way_${local_net_1}_${twNum}thread.log &"
        sleep 25
        check_remote_single_process
        iperf_killer
    done
    
    iperf_env_terminate ${PORT_TYPE} ${PROTOCOL_TYPE}

}

#**function: iperf ,Board as server and custom , two port
function iperf_dual6()
{
    MESSAGE="PASS"

    iperf_env_prepare ${PORT_TYPE} ${PROTOCOL_TYPE}
    
    process="iperf"

    #two-way perfornamce
    iperf_killer

    echo "#############################"
    echo "Run iperf Single port two-way..."
    echo "#############################"
    SendPyte="SingleTwo"
    for twNum in $THREAD
    do
        iperf -s >/dev/null 2>&1 &
		ssh root@$BACK_IP "iperf -s ${IPV6_MASK} >/dev/null 2>&1 &"
        sleep 5

        echo "Run ${PROTOCOL_TYPE} as server and customer dual port two-way ${twNum}thread......"
        ssh root@$BACK_IP "iperf -c ${local_ip_1} ${IPV6_MASK} -t $IPERFDURATION -i 2 -P $twNum > /$LOG_DIR/$IPERFDIR/${PROTOCOL_TYPE}_Single_two-way_${local_net_1}_${twNum}thread.log &"
        ssh root@$BACK_IP "iperf -c ${local_ip_2} ${IPV6_MASK} -t $IPERFDURATION -i 2 -P $twNum > /$LOG_DIR/$IPERFDIR/${PROTOCOL_TYPE}_Single_two-way_${local_net_1}_${twNum}thread.log &"
	iperf -c ${remote_ip_1} ${IPV6_MASK} -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/${PROTOCOL_TYPE}_Single_two-way_${local_net_1}_${twNum}thread.log &
        iperf -c ${remote_ip_2} ${IPV6_MASK} -t $IPERFDURATION -i 2 -P $twNum > $LOG_DIR/$IPERFDIR/${PROTOCOL_TYPE}_Single_two-way_${local_net_1}_${twNum}thread.log &

        sleep 25
        check_dual_process
        iperf_killer
    done
    
    iperf_env_terminate ${PORT_TYPE} ${PROTOCOL_TYPE}

}

function main()
{
    PORT_TYPE=`echo ${TEST_CASE_NUM} | awk -F'_' '{print $2}'`
	echo "The net port type is "${PORT_TYPE}

	PROTOCOL_TYPE=`echo ${TEST_CASE_NUM} | awk -F'_' '{print $3}'`
	echo "The protocol of net is "${PROTOCOL_TYPE}
	
    test_case_switch
}


#check the log directory is existed or not.
prepare_log_dir

#ifconfig IP
ifconfig $NETPORT1 ${LOCALIP1}
ifconfig $NETPORT2 ${LOCALIP2}
ssh root@$BACK_IP "ifconfig $NETPORT1 ${NETIP1};ifconfig $NETPORT2 ${NETIP2};"

main


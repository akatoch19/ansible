#!/bin/bash

export ANSIBLE_FORCE_COLOR=true
export ANSIBLE_HOST_KEY_CHECKING=False
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`


set -x
curl -X POST -H'Content-type:application/x-www-form-urlencoded' "https://api.hipchat.com/v1/rooms/message?format=json&auth_token=78a2a02858efc39a5ede972b05e248&room_id=2293950&from=BirdEyeCI&message=@all+aggregation+deployment+to+FreeProd+Environment+started+by+$2+via+Jenkins&message_format=text&notify=1" -s -o /dev/null
rm -rf inventory/freeprodaggregation
curl --get http://lead.birdeye.com/aggregation/serverlist?env=freeprod | tr " " "\n" > inventory/freeprodaggregation
sed -i '1s/^/[aggregation]\n/' inventory/freeprodaggregation


if [ "X$1" = "Xyes" ];then
   ssh -o StrictHostKeyChecking=no -i ~/papi.pem ubuntu@54.183.34.228 " sudo /etc/init.d/cron stop"
   ssh -o StrictHostKeyChecking=no -i ~/papi.pem ubuntu@54.183.34.228 " sudo /etc/init.d/monit stop"
   mysql  bazaarify -u deployment  -h54.153.40.57  -se "update QRTZ_TRIGGERS set trigger_state='PAUSED' where trigger_state='WAITING';"
	query_Sched1='Insert into QRTZ_PAUSED_TRIGGER_GRPS values('"'"'Sched1'"'"','"'"'_$_ALL_GROUPS_PAUSED_$_'"'"')'
	query_Sched2='Insert into QRTZ_PAUSED_TRIGGER_GRPS values('"'"'Sched2'"'"','"'"'_$_ALL_GROUPS_PAUSED_$_'"'"')'
	query_Sched3='Insert into QRTZ_PAUSED_TRIGGER_GRPS values('"'"'Sched3'"'"','"'"'_$_ALL_GROUPS_PAUSED_$_'"'"')'
	query_Sched4='Insert into QRTZ_PAUSED_TRIGGER_GRPS values('"'"'Sched4'"'"','"'"'_$_ALL_GROUPS_PAUSED_$_'"'"')'
	HOST='54.153.40.57'
	mysql bazaarify -u deployment  -h${HOST} -se "${query_Sched1};"
	mysql bazaarify -u deployment  -h${HOST} -se "${query_Sched2};"
	mysql bazaarify -u deployment  -h${HOST} -se "${query_Sched3};"
	mysql bazaarify -u deployment  -h${HOST} -se "${query_Sched4};"
   

     result="1"
    while [ "$result" != "0" ]
     do
     result=$(mysql bazaarify -u rahul -p71LVC48pf -h54.153.40.57 -se "SELECT count(*) FROM QRTZ_FIRED_TRIGGERS;" | tail -1 )
     sleep 20
    done
    ansible-playbook aggregationwithrestart.yml --private-key=/var/lib/jenkins/ssh-keys/devops_rsa -u devops -i inventory
    sleep 5;
    for servers in `cat aggregationwithrestart.retry`
    do 
      wget -qO- "http://lead.birdeye.com/aggregation/updateserver?env=freeprod&ip="$servers"&status=0&update_status=0&remark=SSH Failed" &> /dev/null;
    done
    sleep 5;
    mysql  bazaarify -u deployment  -h54.153.40.57  -se "truncate table QRTZ_PAUSED_TRIGGER_GRPS;"
    mysql  bazaarify -u deployment  -h54.153.40.57  -se "update QRTZ_TRIGGERS set trigger_state='WAITING' where trigger_state='PAUSED';";
    ssh -o StrictHostKeyChecking=no -i ~/papi.pem ubuntu@54.183.34.228 " sudo /etc/init.d/cron start"
    ssh -o StrictHostKeyChecking=no -i ~/papi.pem ubuntu@54.183.34.228 " sudo touch /tmp/cron_check"
    ssh -o StrictHostKeyChecking=no -i ~/papi.pem ubuntu@54.183.34.228 " sudo /etc/init.d/monit start"
    echo "hi"
fi

if [ "X$1" = "Xno" ];then
    ansible-playbook  aggregation.yml  --private-key=/var/lib/jenkins/ssh-keys/devops_rsa -u devops -i inventory
    for servers in `cat aggregation.retry`
    do
      wget -qO- "http://lead.birdeye.com/aggregation/updateserver?env=freeprod&ip="$servers"&status=0&update_status=0&remark=SSH Failed" &> /dev/null;
    done
fi

if [ "X$1" = "Xrefresh" ];then
ansible-playbook  aggregationwithrefresh.yml  --private-key=/var/lib/jenkins/ssh-keys/devops_rsa -u devops -i inventory
    for servers in `cat aggregationwithrefresh.retry`
    do
      wget -qO- "http://lead.birdeye.com/aggregation/updateserver?env=freeprod&ip="$servers"&status=0&update_status=0&remark=SSH Failed" &> /dev/null;
    done

fi
curl -X POST -H'Content-type:application/x-www-form-urlencoded' "https://api.hipchat.com/v1/rooms/message?format=json&auth_token=78a2a02858efc39a5ede972b05e248&room_id=2293950&from=BirdEyeCI&message=@all+aggregation+deployment+to+FreeProd+Environment+started+by+$2+via+Jenkins+completed&message_format=text&notify=1" -s -o /dev/null

#Below code not required to be enbabled here####
#if [ $? -ne 0 ]
#then
#        echo "${red}Build failed , Check build logs" ${reset}
#        exit 1
#else
#        echo "${green}Finished Build at " `date` ${reset}
#fi


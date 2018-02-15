#!/bin/bash

export ANSIBLE_FORCE_COLOR=true
export ANSIBLE_HOST_KEY_CHECKING=False
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
UPDATENODE=${3}
BRANCH==${4}
cat inventory/demoaggregation

set -x
#curl -X POST -H'Content-type:application/x-www-form-urlencoded' "https://api.hipchat.com/v1/rooms/message?format=json&auth_token=78a2a02858efc39a5ede972b05e248&room_id=2293950&from=BirdEyeCI&message=@all+aggregation+deployment+to+Demo+Environment+started+by+$2+via+Jenkins&message_format=text&notify=1" -s -o /dev/null
if [ "${UPDATENODE}" != "true" ]; then
rm -rf inventory/demoaggregation
curl --get http://lead.birdeye.com/aggregation/serverlist?env=demo | tr " " "\n" > inventory/demoaggregation
sed -i '1s/^/[aggregation]\n/' inventory/demoaggregation
cat inventory/demoaggregation
else 
echo -n ""  >inventory/demoaggregation
echo "[daily-review-agg]" > inventory/demoaggregation
mysql -udeployment  -h 52.8.175.124 -Dbam -e "select hostname from agg_server where server_group='daily-review-agg';" |awk '{print $1}' |grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' >>inventory/demoaggregation
echo "[replies-agg]" >> inventory/demoaggregation
mysql -udeployment  -h 52.8.175.124 -Dbam -e "select hostname from agg_server where server_group='replies-agg';" |awk '{print $1}' |grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' >> inventory/demoaggregation
echo "inventory file "
cat inventory/demoaggregation
fi


if [ "X$1" = "Xyes" ];then
    ansible-playbook --limit  '!35.185.240.68:!34.230.2.255:!54.208.231.217:!54.82.149.117:!54.146.166.18'  aggregationwithrestart.yml --private-key=/var/lib/jenkins/ssh-keys/devops_rsa -u devops -i inventory --extra-vars "UPDATENODE=${3} BRANCH=${4}"
    sleep 5;
    for servers in `cat aggregationwithrestart.retry`
    do 
      wget -qO- "http://lead.birdeye.com/aggregation/updateserver?env=demo&ip="$servers"&status=0&update_status=0&remark=SSH Failed" &> /dev/null;
    done
fi

if [ "X$1" = "Xno" ];
then
    ansible-playbook  --limit '!35.185.240.68:!34.230.2.255:!54.208.231.217:!54.82.149.117:!54.146.166.18'  aggregation.yml  --private-key=/var/lib/jenkins/ssh-keys/devops_rsa  -u devops -i inventory --extra-vars "UPDATENODE=${3} BRANCH=${4}"
    for servers in `cat aggregation.retry`
    do
      wget -qO- "http://lead.birdeye.com/aggregation/updateserver?env=demo&ip="$servers"&status=0&update_status=0&remark=SSH Failed" &> /dev/null;
    done

fi

if [ "X$1" = "Xrefresh" ];
then
    ansible-playbook --limit '!35.185.240.68:!34.230.2.255:!54.208.231.217:!54.82.149.117:!54.146.166.18'  aggregationwithrefresh.yml --private-key=/var/lib/jenkins/ssh-keys/devops_rsa  -u root -i inventory --extra-vars "UPDATENODE=${3} BRANCH=${4}"
    for servers in `cat aggregationwithrefresh.retry`
    do
      wget -qO- "http://lead.birdeye.com/aggregation/updateserver?env=demo&ip="$servers"&status=0&update_status=0&remark=SSH Failed" &> /dev/null;
    done

fi

echo "hi";

#curl -X POST -H'Content-type:application/x-www-form-urlencoded' "https://api.hipchat.com/v1/rooms/message?format=json&auth_token=78a2a02858efc39a5ede972b05e248&room_id=2293950&from=BirdEyeCI&message=@all+aggregation+deployment+to+Demo+Environment+started+by+$2+via+Jenkins+completed&message_format=text&notify=1" -s -o /dev/null

#Below code not required to be enbabled here####
#if [ $? -ne 0 ]
#then
#        echo "${red}Build failed , Check build logs" ${reset}
#        exit 1
#else
#        echo "${green}Finished Build at " `date` ${reset}
#fi


#!/bin/bash

export ANSIBLE_FORCE_COLOR=true

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
if [ $# -eq 0 ]
  then
    echo -e "No arguments supplied\n"
    exit 1
fi

env=${2}
enable_filebeat='false'
if [ ! -z ${3} ] ; then
  branch=${3}
else
  branch='master'
fi
if [ ! -z ${4} ] ; then
  update=${4}
else
  update='false'
fi
dbname="bazaarify"

sleep 30
set -x
#curl -X POST -H'Content-type:application/x-www-form-urlencoded' "https://api.hipchat.com/v1/rooms/message?format=json&auth_token=78a2a02858efc39a5ede972b05e248&room_id=2293950&from=BirdEyeCI&message=@all+started+aggregation+deployment+on+new+server+IP:+${1}+for+first+time+to+${2}-Prod+Environment+via+Jenkins&message_format=text&notify=1" -s -o /dev/null

mysqlUser="root"
mysqlPassword="bazaar360"
if [[ "$env" == "free" ]]
then
  configenv='free'
  mysqlHost="54.153.40.57"
elif [[ "$env" == "paid" ]]
then
  enable_filebeat='true'
  configenv=''
  mysqlHost="db.birdeye.com"
elif [[ "$env" == "demo" ]]
then
  configenv='demo'
  mysqlHost="54.215.1.164"
else
  echo -e "${red}Build failed, MysqlHost not found for env given"
  exit 1
fi

Ansible=`which ansible-playbook`
export ANSIBLE_HOST_KEY_CHECKING=False
$Ansible -e 'host_key_checking=False' aggregation.yml --private-key=/var/lib/jenkins/ssh-keys/devops_rsa -u devops -i "${1}," --extra-vars "env=${2} mysqlUser=${mysqlUser} mysqlPassword=${mysqlPassword} mysqlHost=${mysqlHost} configenv=$configenv Branch=$branch UpdateNode=$update enable_filebeat=${enable_filebeat}"
sleep 5
#fi
if [ $? -ne 0 ]
then
        echo "${red}Build failed , Check build logs" ${reset}
        exit 1
fi
sleep 5
echo -e "\nUpdating IP records for GCloud\n"
/bin/bash /var/lib/jenkins/scripts/launch-gcloud-instance-list.sh
sleep 2
#/bin/bash /var/lib/jenkins/scripts/aws-instance-list.sh
#sleep 1

echo -e "insert host details into database"
MYSQL=`which mysql`
grep -qR ${1} /var/lib/jenkins/scripts/launch
if [ $? -ne 0 ] ;
then
$MYSQL --user=${mysqlUser} --password=${mysqlPassword} --host=${mysqlHost} ${dbname} << EOF 
INSERT INTO ${dbname}.aggregation_server(hostname,create_date,update_remark)VALUES('http://${1}:8080/',now(),'Ready');
EOF
else 
$MYSQL --user=${mysqlUser} --password=${mysqlPassword} --host=${mysqlHost} ${dbname} << EOF 
INSERT INTO ${dbname}.aggregation_server(hostname,create_date,update_remark,vendor_id)VALUES('http://${1}:8080/',now(),'Ready',1);
EOF
fi

if [ $? -ne 0 ]
then
        echo "${red}Build failed , Check build logs" ${reset}
        exit 1
else
        echo "${green}Finished Build at " `date` ${reset}
fi

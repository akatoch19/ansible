#!/bin/bash
export ANSIBLE_FORCE_COLOR=true
export ANSIBLE_HOST_KEY_CHECKING=False
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
Ansible=`which ansible-playbook`

rm instance_id.txt instance_ip.txt
touch instance_id.txt instance_ip.txt


for i in `cat inventory/hosts`;
do
  echo "${green}Stopping job" ${reset}
  curl --silent http://${i}:8080/bam/consumer/pause
  NEXT_WAIT_TIME=0
   echo -e "${green}Waiting for worker to become idle at http://${i}:8080/bam/check/state" ${reset}
  until $(curl --silent http://${i}:8080/bam/check/state | grep -q "Idle") || [ $NEXT_WAIT_TIME -eq 22 ]; do     printf '.';     sleep $(( NEXT_WAIT_TIME++ )) ; done
#  until $(curl --silent http://${i}:8080/bam/check/state | grep -i -q "Idle") || [ $NEXT_WAIT_TIME -eq 4 ]; do echo -n "${green}.." ${reset};     sleep $(( NEXT_WAIT_TIME++ )) ; done
  instance_id=`aws --profile FREE_AGGREGATION_2 --region us-east-1 ec2 describe-instances --filters "Name=ip-address, Values=$i" --query 'Reservations[*].Instances[*].InstanceId' --output text`
  export AWS_PROFILE='FREE_AGGREGATION_2'
  sed -i "/\s\{4,\}instance_ids:$/a \      - '${instance_id}' \\" stop_instances.yaml
  echo ${instance_id} >> instance_id.txt
done
if [ $? -ne 0 ]
then
        echo "${red}Build failed , Check build logs" ${reset}
        exit 1
fi

$Ansible -e 'host_key_checking=False' stop_instances.yaml --private-key=/var/lib/jenkins/ssh-keys/devops_rsa -u devops -i instance_ip.txt --extra-vars "region='us-east-1'"
if [ $? -ne 0 ]
then
        echo "${red}Build failed , Check build logs" ${reset}
        exit 1
fi

echo -e "${green}Waiting for instance to become accessible\n" ${reset}
sleep 60


#Get ip of the server from instance id
for i in `cat instance_id.txt`;
do 
  instance_ip=`aws --profile FREE_AGGREGATION_2 --region us-east-1 ec2 describe-instances --filters "Name=instance-id, Values=$i" --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text`
  echo ${instance_ip} >> instance_ip.txt
done

sleep 1

echo -e "${green}Going to update DB table\n" ${reset}
#change db entry
DB_HOST='demodb.birdeye.com'
username='devops'
password='devopsWrt90655'

#while read -r -u 4 line1 && read -r -u 5 line2;
while read line1 <&4 && read line2 <&5;
do
  echo "Host IP to be replced: $line1"
  echo "Host IP to be replaced with: $line2"
  query="update agg_server set hostname=\"http://${line2}:8080/\" where hostname like \"%${line1}%\""
  QUERY_RESULT=`mysql -u devops -pdevopsWrt90655 -D bam -h ${DB_HOST} --skip-column-names -e "begin;$query;commit"`
     if [ $? -ne 0 ]
     then
        echo "${red}mysql query execution failed - $QUERY" ${reset}
        exit 1
    fi
done 4<inventory/hosts 5<instance_ip.txt

echo -e "${green}Starting playbook to start the services\n" ${reset}
sleep 30

$Ansible -e 'host_key_checking=False' restart-node.yaml --private-key=/var/lib/jenkins/ssh-keys/devops_rsa -u devops -i instance_ip.txt
if [ $? -ne 0 ]
then
        echo "${red}Build failed , Check build logs" ${reset}
        exit 1
else
        echo "${green}Finished Build at " `date` ${reset}
fi

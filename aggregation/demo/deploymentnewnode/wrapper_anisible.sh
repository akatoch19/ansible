#!/bin/bash

export ANSIBLE_FORCE_COLOR=true
export ANSIBLE_HOST_KEY_CHECKING=False
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`


set -x


if [ "X$1" = "Xyes" ];then
    ansible-playbook aggregationwithrestart.yml --private-key=/var/lib/jenkins/ssh-keys/devops_rsa -u devops -i inventory
    sleep 5;
    #for servers in `cat aggregationwithrestart.retry`
    #do 
    #  wget -qO- "http://lead.birdeye.com/aggregation/updateserver?env=demo&ip="$servers"&status=0&update_status=0&remark=SSH Failed" &> /dev/null;
    #done
fi

if [ "X$1" = "Xno" ];
then
    ansible-playbook  aggregation.yml  --private-key=/var/lib/jenkins/ssh-keys/devops_rsa  -u devops -i inventory
   # for servers in `cat aggregation.retry`
   # do
   #   wget -qO- "http://lead.birdeye.com/aggregation/updateserver?env=demo&ip="$servers"&status=0&update_status=0&remark=SSH Failed" &> /dev/null;
   # done

fi

if [ "X$1" = "Xrefresh" ];
then
    ansible-playbook  aggregationwithrefresh.yml --private-key=/var/lib/jenkins/ssh-keys/devops_rsa  -u root -i inventory
   # for servers in `cat aggregationwithrefresh.retry`
   # do
   #   wget -qO- "http://lead.birdeye.com/aggregation/updateserver?env=demo&ip="$servers"&status=0&update_status=0&remark=SSH Failed" &> /dev/null;
   # done

fi

echo "hi";


#Below code not required to be enbabled here####
#if [ $? -ne 0 ]
#then
#        echo "${red}Build failed , Check build logs" ${reset}
#        exit 1
#else
#        echo "${green}Finished Build at " `date` ${reset}
#fi


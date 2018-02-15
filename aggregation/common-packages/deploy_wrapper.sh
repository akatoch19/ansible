#!/bin/bash
export ANSIBLE_FORCE_COLOR=true
export ANSIBLE_HOST_KEY_CHECKING=False
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

ansible-playbook install_base.yml --private-key=/home/pratap/workdir/sshkeys/devops_rsa -u devops -i inventory
#ansible-playbook install_base.yml --private-key=/home/pratap//workdir/sshkeys/freeprodverginia.pem -u ubuntu -i inventory
#ansible-playbook install_base.yml  -u root -i inventory
if [ $? -ne 0 ]
then
        echo "${red}Build failed , Check build logs" ${reset}
        exit 1
else
        echo "${green}Finished Build at " `date` ${reset}
fi

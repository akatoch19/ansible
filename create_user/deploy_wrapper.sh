#!/bin/bash 
export ANSIBLE_HOST_KEY_CHECKING=False
#curl --get http://lead.birdeye.com/aggregation/serverlist?env=freeprod | tr " " "\n" > inventory/freeprodaggregation
#ansible-playbook create_user.yml --private-key=/Users/kunwarpratapsingh/workdir/sshkeys/devops_rsa -u devops -i inventory --extra-vars "name=${1} pubrsafile=${2}"
#ansible-playbook create_user.yml --private-key=/Users/kunwarpratapsingh/workdir/sshkeys/production-key.pem -u ec2-user -i inventory --extra-vars "name=${1} pubrsafile=${2}"
ansible-playbook create_user.yml  -e 'host_key_checking=False' --private-key=/Users/kunwarpratapsingh/workdir/sshkeys/${5} -u ${3} -i ${4} --extra-vars "name=${1} pubrsafile=${2}"

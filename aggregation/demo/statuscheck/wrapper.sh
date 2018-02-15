#!/bin/bash
set -x 
export ANSIBLE_FORCE_COLOR=true
export ANSIBLE_HOST_KEY_CHECKING=False
rm -rf inventory/demoaggregation
curl --get http://lead.birdeye.com/aggregation/serverlist?env=demo | tr " " "\n" > inventory/demoaggregation
sed -i '1s/^/[aggregation]\n/' inventory/demoaggregation


ansible-playbook aggregation.yml  --private-key=/var/lib/jenkins/ssh-keys/devops_rsa -u devops  -i inventory/
for servers in `cat aggregation.retry`
    do
      wget -qO- "http://lead.birdeye.com/aggregation/updateserver?env=demo&ip="$servers"&status=0&update_status=0&remark=SSH Failed" &> /dev/null;
    done

echo "hi";





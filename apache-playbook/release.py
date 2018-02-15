import boto.ec2
import boto.ec2.elb
import boto.ec2.autoscale
from   fabric.api import env, run, cd, settings, sudo
from   fabric.api import parallel
from   fabric.api import local


AWS_REGION = 'us-west-1'
PROFILE = 'PAID_PROD_TERRAFORM'

#EC2_CONN = boto.ec2.EC2Connection(profile_name=PROFILE, region=boto.ec2.get_region(AWS_REGION))
EC2_CONN = boto.ec2.connect_to_region('us-west-1', profile_name='PAID_PROD_TERRAFORM')
#REG = boto.regioninfo.RegionInfo(name=AWS_REGION,endpoint=endpt)
#ELB_CONN = boto.ec2.elb_connect(profile_name=PROFILE, region=boto.ec2.get_region(AWS_REGION))
ELB_CONN = boto.ec2.elb.connect_to_region(AWS_REGION, profile_name=PROFILE)


ELBS = ['ProdUILB']


def get_instances_from_elb(LB_LIST):
    """
    """
    if not LB_LIST:
        print "invalid parameters"
        return []

    if not isinstance(LB_LIST, list):
        print "invalid parameters"
        return []

    LB = ELB_CONN.get_all_load_balancers(LB_LIST)
    if not LB:
        print "no such load balancer"
        return []

    instances = []
    for i in LB:
        instances.extend(i.instances)

    return [i.id for i in instances]


def get_ips_from_instanceids(ID_LIST):
    """
    """
    if not ID_LIST:
        print "invalid parameters"
        return []

    if not isinstance(ID_LIST, list):
        print "invalid parameters"
        return []

    reservations = EC2_CONN.get_all_instances(ID_LIST)
    ips = []
    fl = open('inventory/ProdUILB','w')
    fl.write("[ProdUILB]")
    for i in reservations:
        for j in i.instances:
            ips.append(j.ip_address)
	    fl.write("\n%s" %(j.ip_address))
    fl.close()
    return ips 


def set_hosts_from_elbs():
    instance_ids = get_instances_from_elb(ELBS)
    env.hosts = get_ips_from_instanceids(instance_ids)
    print env.hosts

#!/bin/bash
cd /home/vagrant/devstack
source openrc admin admin

# Report stack.sh run time
devstart=`head -n 1 /home/vagrant/devstack/logs/stack.sh.log | awk '{ print $2 }' | cut -d . -f 1`
devstop=`tail -n 9 /home/vagrant/devstack/logs/stack.sh.log | grep -m1 2015 | awk '{ print $2 }' | cut -d . -f 1`
startdate=$(date -u -d "$devstart" +"%s")
enddate=$(date -u -d "$devstop" +"%s")
runtime=`date -u -d "0 $enddate sec - $startdate sec" +"%H:%M:%S"`

echo " -----------------------------"
echo " | DEVSTACK START:  $devstart |"
echo " | DEVSTACK STOP:   $devstop |"
echo " -----------------------------"
echo " | TOTAL RUN TIME:  $runtime |"
echo " -----------------------------"
echo ""

# generate a keypair and make it available via share
cd /home/vagrant
ssh-keygen -t rsa -N "" -f /home/vagrant/.ssh/vm_key
cp -f /home/vagrant/.ssh/vm_key /vagrant/vm_key
cp -f /home/vagrant/.ssh/vm_key /home/vagrant/vm_key

# add the vagrant keypair and open up security groups
cd /home/vagrant/devstack
for user in admin demo; do
  source openrc $user $user
  nova keypair-add --pub-key /home/vagrant/.ssh/vm_key.pub vagrant
  nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
  nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
  nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
  nova secgroup-add-rule default tcp 80 80 0.0.0.0/0
  nova secgroup-add-rule default tcp 443 443 0.0.0.0/0
done

# use the google dns server as a sane default
neutron subnet-update public-subnet --dns_nameservers list=true 8.8.8.8
neutron subnet-update private-subnet --dns_nameservers list=true 8.8.8.8

# cd /home/vagrant/devstack
# source openrc demo demo

# boot a cirros instance
# nova boot --flavor m1.tiny --image cirros-0.3.2-x86_64-uec --key-name vagrant cirros
# sleep 15
# nova list

# assign a floating ip
# fixed_ip=`nova list --name cirros | tail -n2 | head -n1 | awk '{print $12}' | awk -F= '{ print $2 }' | sed -e 's/,//g'`
# device_id=`nova list --name cirros | tail -n2 | head -n1 | awk '{print $2}'`
# port_id=`neutron port-list -c id -- --device_id $device_id | tail -n2 | head -n1 | awk '{print $2}'`
# neutron floatingip-create --fixed-ip-address $fixed_ip --port-id $port_id public

# sleep 5

# nova list

# Create a flavor, image and boot new image
# cd /home/vagrant/devstack
# source openrc admin admin
# cd /home/vagrant/devstack/files
# wget http://cloud-images.ubuntu.com/releases/14.04/release/ubuntu-14.04-server-cloudimg-amd64-disk1.img
# glance image-create --name ubuntu-qcow2 --file ubuntu-14.04-server-cloudimg-amd64-disk1.img --is-public True --progress --disk-format qcow2 --container-format bare
# nova flavor-create --is-public true m1.custom 6 1 4 1

# cd /home/vagrant/devstack
# source openrc demo demo
# nova boot --flavor m1.custom --image ubuntu-qcow2 --key-name vagrant ubuntu

# sleep 15

# nova list

# create nova instances on private network
nova boot --image $(nova image-list | awk '/ cirros-0.3.0-x86_64-disk / {print $2}') --flavor 1 --nic net-id=$(neutron net-list | awk '/ private / {print $2}'),v4-fixed-ip=10.0.0.101 --key-name vagrant node1
nova boot --image $(nova image-list | awk '/ cirros-0.3.0-x86_64-disk / {print $2}') --flavor 1 --nic net-id=$(neutron net-list | awk '/ private / {print $2}'),v4-fixed-ip=10.0.0.102 --key-name vagrant node2
sleep 15
nova list 

#add secgroup rule to allow ssh etc..
neutron security-group-rule-create default --protocol icmp
neutron security-group-rule-create default --protocol tcp --port-range-min 22 --port-range-max 22
neutron security-group-rule-create default --protocol tcp --port-range-min 80 --port-range-max 80

neutron lbaas-loadbalancer-create --name lb1 private-subnet
neutron lbaas-listener-create --loadbalancer lb1 --protocol HTTP --protocol-port 80 --name listener1
neutron lbaas-pool-create --lb-algorithm ROUND_ROBIN --listener listener1 --protocol HTTP --name pool1
neutron lbaas-member-create  --subnet private-subnet --address 10.0.0.101 --protocol-port 80 pool1
neutron lbaas-member-create  --subnet private-subnet --address 10.0.0.102 --protocol-port 80 pool1


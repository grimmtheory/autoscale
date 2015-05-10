#!/bin/bash

echo "Sourcing admin-admin..."; cd /home/vagrant/devstack; source openrc admin admin

# generate a keypair and make it available via share
echo "Generating keypair..."
cd /home/vagrant
ssh-keygen -t rsa -N "" -f /home/vagrant/.ssh/vm_key
cp -f /home/vagrant/.ssh/vm_key /vagrant/vm_key
cp -f /home/vagrant/.ssh/vm_key /home/vagrant/vm_key
sudo chmod +r /home/vagrant/.ssh/vm_key
sudo chmod +r /home/vagrant/vm_key
sudo chmod +r /vagrant/vm_key
cat /home/vagrant/vm_key

# add the vagrant keypair and open up security groups
echo "Adding keypair and creating security group rules..."
cd /home/vagrant/devstack
for user in admin demo; do
  source openrc $user $user
  nova keypair-add --pub-key /home/vagrant/.ssh/vm_key.pub vagrant
  nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
  nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
  nova secgroup-add-rule default tcp 80 80 0.0.0.0/0
  nova secgroup-add-rule default tcp 443 443 0.0.0.0/0
done

# use the google dns server as a sane default
echo "Adding DNS servers to subnets..."
echo "Sourcing admin-admin..."; source /home/vagrant/devstack/openrc admin admin
neutron subnet-update public-subnet --dns_nameservers list=true 8.8.8.8
neutron subnet-update private-subnet --dns_nameservers list=true 8.8.8.8
neutron subnet-list
neutron subnet-show private-subnet
neutron subnet-show public-subnet
sleep 5

# setup web instances
echo "Setting up web instances..."
echo "Sourcing admin-demo..."; source /home/vagrant/devstack/openrc admin demo
num=1
while [ $num -le 3 ]; do
  nova boot --image $(nova image-list | awk '/ cirros-0.3.4-x86_64-uec / {print $2}') --flavor 1 --nic net-id=$(neutron net-list | awk '/ private / {print $2}'),v4-fixed-ip=10.0.0.10$num --key-name vagrant node$num
  sleep 30
  num=$(( $num + 1 ))
done
nova list
nova show node1
nova show node2
nova show node3

# Create neutron security groups
echo "Setting up neutron security group rules..."
echo "Sourcing admin-demo..."; source /home/vagrant/devstack/openrc admin demo
neutron security-group-rule-create default --protocol icmp
neutron security-group-rule-create default --protocol tcp --port-range-min 22 --port-range-max 22
neutron security-group-rule-create default --protocol tcp --port-range-min 80 --port-range-max 80
sleep 5
neutron security-group-rule-list

# Create load balancer pool
echo "Creating load balancer pool..."
echo "Sourcing admin-demo..."; source /home/vagrant/devstack/openrc admin demo
subnetid=`neutron subnet-list | grep " private" | awk '{ print $2 }'`
neutron lb-pool-create --lb-method ROUND_ROBIN --name pool1 --protocol HTTP --subnet-id $subnetid
sleep 10
neutron lb-pool-list

# Add load balancer members
echo "Adding load balancer pool members"
echo "Sourcing admin-demo..."; source /home/vagrant/devstack/openrc admin demo
num=1
while [ $num -le 3 ]; do
  neutron lb-member-create --address 10.0.0.10$num --protocol-port 80 pool1
  sleep 5
  num=$(( $num + 1 ))
done
sleep 5
neutron lb-member-list

# Setup load balancer health monitor
echo "Creating load balancer health monitor..."
echo "Sourcing admin-demo..."; source /home/vagrant/devstack/openrc admin demo
neutron lb-healthmonitor-create --delay 3 --type HTTP --max-retries 3 --timeout 3
healthmonitorid=`neutron lb-healthmonitor-list | grep HTTP | awk '{ print $2 }'`
neutron lb-healthmonitor-associate $healthmonitorid pool1
sleep 5
neutron lb-healthmonitor-list

# Create load balancer vip
echo "Creating load balancer vip..."
echo "Sourcing admin-demo..."; source /home/vagrant/devstack/openrc admin demo
subnetid=`neutron subnet-list | grep " private" | awk '{ print $2 }'`
neutron lb-vip-create --name vip-10.0.0.100 --protocol-port 80 --protocol HTTP --subnet-id $subnetid --address 10.0.0.100 pool1
sleep 5
neutron lb-vip-list

# Add load balancer floating ip
echo "Adding floating ip to load balancer..."
echo "Sourcing admin-demo..."; source /home/vagrant/devstack/openrc admin demo
cd /home/vagrant/devstack; source openrc admin demo
portid=`neutron port-list | grep 10.0.0.100 | awk '{ print $2 }'`
neutron floatingip-create --port-id $portid --fixed-ip-address 10.0.0.100 --floating-ip-address 192.168.27.100 public
sleep 5
neutron floatingip-list

# Setup web responses
echo "Disabling strict host checking to enable ssh and scp pass-thru without host key checking prompts"
echo "Host *" > /home/vagrant/.ssh/config
echo "    StrictHostKeyChecking no" > /home/vagrant/.ssh/config
cat /home/vagrant/.ssh/config

# Turn on an http listener for each host
for ip in 10.0.0.101 10.0.0.102 10.0.0.103; do
  echo "while true; do echo -e 'HTTP/1.0 200 OK\r\n\r\nYou are connected to $ip' | sudo nc -l -p 80 ; done &" > /home/vagrant/$ip.sh
  chmod +x /home/vagrant/$ip.sh
  scp -i /home/vagrant/vm_key /home/vagrant/$ip.sh cirros@$ip:/home/cirros/http.sh
  ssh -i /home/vagrant/vm_key -o BatchMode=yes cirros@$ip '/home/cirros/http.sh'
  ssh -i /home/vagrant/vm_key -o BatchMode=yes cirros@$ip 'ps -ef | grep http | grep -v grep'
  sleep 15
  curl http://$ip
done

# Test internal vip
echo ""
echo "Testing internal vip 10.0.0.100..."
curl http://10.0.0.100
curl http://10.0.0.100
curl http://10.0.0.100
echo ""
echo "Testing internal vip 192.168.27.100..."
curl http://192.168.27.100
curl http://192.168.27.100
curl http://192.168.27.100


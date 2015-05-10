#!/bin/bash

cd /home/vagrant/devstack; source openrc admin admin

# generate a keypair and make it available via share
cd /home/vagrant
ssh-keygen -t rsa -N "" -f /home/vagrant/.ssh/vm_key
cp -f /home/vagrant/.ssh/vm_key /vagrant/vm_key
cp -f /home/vagrant/.ssh/vm_key /home/vagrant/vm_key
sudo chmod +r /home/vagrant/.ssh/vm_key
sudo chmod +r /home/vagrant/vm_key
sudo chmod +r /vagrant/vm_key

# add the vagrant keypair and open up security groups
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
neutron subnet-update public-subnet --dns_nameservers list=true 8.8.8.8
neutron subnet-update private-subnet --dns_nameservers list=true 8.8.8.8

sleep 5

cd /home/vagrant/devstack; source openrc admin demo

# setup web instances
num=1
while [ $num -le 3 ]; do
  nova boot --image $(nova image-list | awk '/ cirros-0.3.4-x86_64-uec / {print $2}') --flavor 1 --nic net-id=$(neutron net-list | awk '/ private / {print $2}'),v4-fixed-ip=10.0.0.10$num --key-name vagrant node$num
  sleep 5
  num=$(( $num + 1 ))
done

# Create neutron security groups
neutron security-group-rule-create default --protocol icmp
neutron security-group-rule-create default --protocol tcp --port-range-min 22 --port-range-max 22
neutron security-group-rule-create default --protocol tcp --port-range-min 80 --port-range-max 80

sleep 5

# Create load balancer pool
subnetid=`neutron subnet-list | grep " private" | awk '{ print $2 }'`
neutron lb-pool-create --lb-method ROUND_ROBIN --name pool1 --protocol HTTP --subnet-id $subnetid

sleep 10

# Add load balancer members
num=1
while [ $num -le 3 ]; do
  neutron lb-member-create --address 10.0.0.10$num --protocol-port 80 pool1
  sleep 5
  num=$(( $num + 1 ))
done

sleep 5

# Setup load balancer health monitor
neutron lb-healthmonitor-create --delay 3 --type HTTP --max-retries 3 --timeout 3
healthmonitorid=`neutron lb-healthmonitor-list | grep HTTP | awk '{ print $2 }'`
neutron lb-healthmonitor-associate $healthmonitorid pool1

sleep 5

# Create load balancer vip
subnetid=`neutron subnet-list | grep " private" | awk '{ print $2 }'`
neutron lb-vip-create --name vip-10.0.0.100 --protocol-port 80 --protocol HTTP --subnet-id $subnetid --address 10.0.0.100 pool1

sleep 5

# Add load balancer floating ip
cd /home/vagrant/devstack; source openrc admin demo
portid=`neutron port-list | grep 10.0.0.100 | awk '{ print $2 }'`
neutron floatingip-create --port-id $portid --fixed-ip-address 10.0.0.100 --floating-ip-address 192.168.27.100 public

# Setup web responses
# Disable strict host checking to enable pass-thru without prompts
echo "Host *" > /home/vagrant/.ssh/config
echo "    StrictHostKeyChecking no" > /home/vagrant/.ssh/config

# Turn on an http listener for each host
echo "while true; do echo -e 'HTTP/1.0 200 OK\r\n\r\nYou are connected to 10.0.0.101' | sudo nc -l -p 80 ; done &" > /home/vagrant/http1.sh

sleep 3

echo "while true; do echo -e 'HTTP/1.0 200 OK\r\n\r\nYou are connected to 10.0.0.102' | sudo nc -l -p 80 ; done &" > /home/vagrant/http2.sh

sleep 3

echo "while true; do echo -e 'HTTP/1.0 200 OK\r\n\r\nYou are connected to 10.0.0.103' | sudo nc -l -p 80 ; done &" > /home/vagrant/http3.sh

sleep 3

chmod +x /home/vagrant/http*.sh

scp -i /home/vagrant/.ssh/vm_key /home/vagrant/http1.sh cirros@10.0.0.101:/home/cirros/http.sh

sleep 3

scp -i /home/vagrant/.ssh/vm_key /home/vagrant/http2.sh cirros@10.0.0.102:/home/cirros/http.sh

sleep 3

scp -i /home/vagrant/.ssh/vm_key /home/vagrant/http3.sh cirros@10.0.0.103:/home/cirros/http.sh

sleep 3

ssh -i /home/vagrant/.ssh/vm_key cirros@10.0.0.101 "/home/cirros/http.sh"

sleep 3

ssh -i /home/vagrant/.ssh/vm_key cirros@10.0.0.102 "/home/cirros/http.sh"

sleep 3

ssh -i /home/vagrant/.ssh/vm_key cirros@10.0.0.103 "/home/cirros/http.sh"

sleep 3


# Test internal vip
echo "Testing internal vip 10.0.0.100..."
curl http://10.0.0.100
curl http://10.0.0.100
curl http://10.0.0.100
echo ""
echo "Testing internal vip 192.168.27.100..."
curl http://192.168.27.100
curl http://192.168.27.100
curl http://192.168.27.100


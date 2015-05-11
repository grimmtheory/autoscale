#!/bin/bash
# Report stack.sh run time - Stack.sh used to report run time, since they've removed that add it back
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

# Source credential functions to allow easy swapping between creds as needed
sourceadmin () { echo "Sourcing admin..."; source /home/vagrant/devstack/openrc admin admin; }
sourcedemo () { echo "Sourcing demo..."; source /home/vagrant/devstack/openrc admin demo; }

sourceadmin

## SET PROXY TO SPEED UP BUILDS, REMOVE OR CONFIGURE AS NECESSARY

export HTTP_PROXY=http://192.168.33.1:8889/
export http_proxy=$HTTP_PROXY

## SET PROXY TO SPEED UP BUILDS, REMOVE OR CONFIGURE AS NECESSARY


# generate a keypair and make it available via share
echo "Generating keypair..."
key=/home/vagrant/.ssh/id_rsa
ssh-keygen -t rsa -N "" -f $key
chown -R vagrant:vagrant /home/vagrant
chmod 600 $key
chmod 644 $key.pub

# add the vagrant keypair and open up security groups
echo "Adding keypair and creating security group rules..."
cd /home/vagrant/devstack
for user in admin demo; do
  source openrc $user $user
  nova keypair-add --pub-key $key.pub vagrant
  nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
  nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
  nova secgroup-add-rule default tcp 80 80 0.0.0.0/0
  nova secgroup-add-rule default tcp 443 443 0.0.0.0/0
done

# use the google dns server as a sane default
echo "Adding DNS servers to subnets..."
sourceadmin
neutron subnet-update public-subnet --dns_nameservers list=true 8.8.8.8
neutron subnet-update private-subnet --dns_nameservers list=true 8.8.8.8
neutron subnet-list
neutron subnet-show private-subnet
neutron subnet-show public-subnet
sleep 5

# Setup web instances
echo "Setting up web instances..."
sourcedemo

# Create script for cloud-init to use to start the web listener in the instances
cat << HTTP > /home/vagrant/http.txt
#!/bin/sh
ip=`ifconfig eth0 | grep Bcast | awk '{ print $2 }' | awk -F: '{ print $2 }' | sed -e 's/ //g'`
while true; do echo -e 'HTTP/1.0 200 OK\r\n\r\nYou are connected to $ip' | sudo nc -l -p 80 ; done &
HTTP
chmod +rx /home/vagrant/http.txt
chown vagrant:vagrant /home/vagrant/http.txt

# Create custom flavor
nova flavor-create --is-public true m1.micro 6 128 1 1

# Spawn instances
num=1
while [ $num -le 3 ]; do
  nova boot --image $(nova image-list | awk '/ cirros-0.3.4-x86_64-uec / {print $2}') --flavor 6 --user-data /home/vagrant/http.txt --nic net-id=$(neutron net-list | awk '/ private / {print $2}'),v4-fixed-ip=10.0.0.10$num --key-name vagrant node$num
  sleep 30
  nova show node$num
  num=$(( $num + 1 ))
done
nova list

# Create load balancer pool
echo "Creating load balancer pool..."
sourcedemo
subnetid=`neutron subnet-list | grep " private" | awk '{ print $2 }'`
neutron lb-pool-create --lb-method ROUND_ROBIN --name pool1 --protocol HTTP --subnet-id $subnetid
sleep 10
neutron lb-pool-list

# Add load balancer members
echo "Adding load balancer pool members"
sourcedemo
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
sourcedemo
neutron lb-healthmonitor-create --delay 3 --type HTTP --max-retries 3 --timeout 3
healthmonitorid=`neutron lb-healthmonitor-list | grep HTTP | awk '{ print $2 }'`
neutron lb-healthmonitor-associate $healthmonitorid pool1
sleep 5
neutron lb-healthmonitor-list

# Create load balancer vip
echo "Creating load balancer vip..."
sourcedemo
subnetid=`neutron subnet-list | grep " private" | awk '{ print $2 }'`
neutron lb-vip-create --name vip-10.0.0.100 --protocol-port 80 --protocol HTTP --subnet-id $subnetid --address 10.0.0.100 pool1
sleep 5
neutron lb-vip-list

# Add load balancer floating ip
echo "Adding floating ip to load balancer..."
sourcedemo
portid=`neutron port-list | grep 10.0.0.100 | awk '{ print $2 }'`
neutron floatingip-create --port-id $portid --fixed-ip-address 10.0.0.100 --floating-ip-address 192.168.27.100 public
sleep 5
neutron floatingip-list

# Turn on an http listener for each host
# for ip in 10.0.0.101 10.0.0.102 10.0.0.103; do
#   ssh -i $key -o BatchMode=yes -o StrictHostKeyChecking=no cirros@$ip "while true; do echo -e 'HTTP/1.0 200 OK\r\n\r\nYou are connected to $ip' | sudo nc -l -p 80 ; done &"
#   sleep 5
# done

# Testing VIPs
# Unset http proxy (if configured)
export HTTP_PROXY=""
export http_proxy=""
echo ""
for vip in 10.0.0.100 192.168.27.100; do
  echo ""; echo "Testing $vip..."
  num=1
  while [[ num++ -lt 6 ]]; do
    ip=`curl --connect-timeout 1 http://$vip 2> /dev/null`
    echo "Testing http to $vip...returns...$ip"
  done
done


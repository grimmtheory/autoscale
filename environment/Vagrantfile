# -*- mode: ruby -*-
# vi: set ft=ruby :

### SET GLOBAL VARIABLES ###

# Set network info
HOST_IP = "192.168.33.2"
DNS = "10.0.2.3"
PUBLIC_NETWORK = "192.168.27"
VM_NAME = "devstack"

# Set DevStack info
DEVSTACK_BRANCH = "master"
DEVSTACK_PASSWORD = "stack"

#### BEGIN VAGRANT HW CONFIG ###

Vagrant.configure("2") do |config|

  # Select distribution and build for the box
  config.vm.box = "ubuntu/trusty64"

  # set the hostname, otherwise qrouter will be lost upon reload
  config.vm.hostname = "#{VM_NAME}"

  # eth1, this will be the management endpoint
  config.vm.network :private_network, ip: "#{HOST_IP}"

  # eth2, this will be the "public" VM network
  config.vm.network :private_network, ip: "#{PUBLIC_NETWORK}.2", netmask: "255.255.255.0", auto_config: false

  # virtual-box specific settings
  config.vm.provider :virtualbox do |vb|

    # Lable the virtual machine
    vb.name = "#{VM_NAME}"

    # Enable the Virtual Box GUI on boot, i.e. not "headless"
    vb.gui = true

    # Set CPU and memoru size
    vb.customize ["modifyvm", :id, "--cpus", "1"]
    vb.customize ["modifyvm", :id, "--memory", 4096]

    # Enable promiscuous mode on eth2 for floating IPs to be accessible
    vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]

  end

  # Suppress tty messages
  config.vm.provision "fix-no-tty", type: "shell" do |s|
    s.privileged = false
    s.inline = "sudo sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile"
  end

  # Begin in-line script
  config.vm.provision "shell", inline: <<-EOF

    # Install git
    apt-get update
    apt-get -y install git

    # Clone the devstack repo
    git clone https://github.com/openstack-dev/devstack.git /home/vagrant/devstack

    # Clone the heat-templates repo
    git clone https://github.com/openstack/heat-templates.git /home/vagrant/heat-templates

    # Clone the autoscale repo
    git clone https://github.com/grimmtheory/autoscale.git /home/vagrant/autoscale

    # Configure devstack
    cd /home/vagrant/devstack
    cat << CONF > /home/vagrant/devstack/local.conf
[[local|localrc]]
HOST_IP=#{HOST_IP}
DEVSTACK_BRANCH=#{DEVSTACK_BRANCH}
DEVSTACK_PASSWORD=#{DEVSTACK_PASSWORD}

EXTRA_OPTS=(metadata_host=$HOST_IP)
Q_DHCP_EXTRA_DEFAULT_OPTS=(enable_metadata_network=True enable_isolated_metadata=True)

KEYSTONE_BRANCH=#{DEVSTACK_BRANCH}
NOVA_BRANCH=#{DEVSTACK_BRANCH}
NEUTRON_BRANCH=#{DEVSTACK_BRANCH}
GLANCE_BRANCH=#{DEVSTACK_BRANCH}
CINDER_BRANCH=#{DEVSTACK_BRANCH}
HEAT_BRANCH=#{DEVSTACK_BRANCH}
HORIZON_BRANCH=#{DEVSTACK_BRANCH}

# Default passwords
ADMIN_PASSWORD=#{DEVSTACK_PASSWORD}
MYSQL_PASSWORD=#{DEVSTACK_PASSWORD}
RABBIT_PASSWORD=#{DEVSTACK_PASSWORD}
SERVICE_PASSWORD=#{DEVSTACK_PASSWORD}
SERVICE_TOKEN=#{DEVSTACK_PASSWORD}

SCREEN_LOGDIR=/opt/stack/logs
LOGFILE=/home/vagrant/devstack/logs/stack.sh.log
INSTANCES_PATH=/home/vagrant/instances

# Disable unwanted services
# Disable nova network
disable_service n-net
# Disable tempest
disable_service tempest
# Disable sahara
disable_service sahara
# Disable trove
disable_service trove
disable_service tr-api
disable_service tr-mgr
disable_service tr-cond
# Disable swift
disable_service s-proxy
disable_service s-object
disable_service s-container
disable_service s-account
# Disable cinder
disable_service cinder
disable_service c-api
disable_service c-vol
disable_service c-sch
disable_service c-bak

# Enable Cinder services
# enable_service cinder
# enable_service c-api
# enable_service c-vol
# enable_service c-sch
# enable_service c-bak

# Configure Cinder services
# VOLUME_GROUP="stack-volumes"
# VOLUME_NAME_PREFIX="volume-"
# VOLUME_BACKING_FILE_SIZE=250M

# Enable Database Backend MySQL
enable_service mysql

# Enable RPC Backend RabbitMQ
enable_service rabbit

# Enable Keystone - OpenStack Identity Service
enable_service key

# Enable Horizon - OpenStack Dashboard Service
enable_service horizon

# Enable Glance - OpenStack Image Registry service 
enable_service g-api
enable_service g-reg

# Enable Neutron
enable_service q-svc
enable_service q-agt
enable_service q-dhcp
enable_service q-l3
enable_service q-meta
enable_service q-lbaas
enable_service neutron

# Configure Neutron
FLAT_INTERFACE=eth2
PUBLIC_INTERFACE=eth2
FIXED_RANGE=10.0.0.0/24
FLOATING_RANGE=#{PUBLIC_NETWORK}.0/24
PUBLIC_NETWORK_GATEWAY=#{PUBLIC_NETWORK}.2
Q_FLOATING_ALLOCATION_POOL=start=#{PUBLIC_NETWORK}.3,end=#{PUBLIC_NETWORK}.254

# Enable Ceilometer - Metering Service (metering + alarming)
enable_service ceilometer-collector
enable_service ceilometer-acompute
enable_service ceilometer-acentral
enable_service ceilometer-anotification
enable_service ceilometer-api
enable_service ceilometer-alarm-notifier
enable_service ceilometer-alarm-evaluator

# Enable Heat - Orchestration Service
enable_service heat
enable_service h-api
enable_service h-api-cfn
enable_service h-api-cw
enable_service h-eng
CONF

    # Set passwords
    echo root:stack | chpasswd
    echo vagrant:stack | chpasswd

    # Add source creds to vagrant .bash_profile
    echo "source /home/vagrant/devstack/openrc admin demo" >> /home/vagrant/.bash_profile

    # fix permissions as the cloned repo is owned by root
    chown -R vagrant:vagrant /home/vagrant

    # fix routing so that VMs can reach out to the internets
    cat << SYSCTL > /etc/sysctl.d/60-devstack.conf
net.ipv4.conf.eth0.proxy_arp = 1
net.ipv4.ip_forward = 1
SYSCTL
    sysctl --system
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

    # bring up eth2
    ip link set dev eth2 up

    # setup devstack
    cd /home/vagrant/devstack
    sudo -u vagrant env HOME=/home/vagrant ./stack.sh

    # fix network setup to make VMs pingable from inside and outside devstack
    ovs-vsctl add-port br-ex eth2

    # Setup the eth2 interfaces file
    cat << ETH2 > /etc/network/interfaces.d/eth2.cfg
auto eth2
iface eth2 inet manual
ETH2

    # Setup the br-ex interfaces file
    cat << BREX > /etc/network/interfaces.d/br-ex.cfg
auto br-ex
iface br-ex inet static
      address "#{PUBLIC_NETWORK}.2"
      netmask 255.255.255.0
      up ip route add 10.0.0.0/24 via "#{PUBLIC_NETWORK}.3" dev br-ex
BREX

    # Begin post tasks
    cd /home/vagrant

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
sourceadmin () { echo "Sourcing user admin and project admin..."; source /home/vagrant/devstack/openrc admin admin; }
sourcedemo () { echo "Sourcing user admin and project demo..."; source /home/vagrant/devstack/openrc admin demo; }

sourceadmin

# generate a keypair and make it available via share
echo "Generating keypair..."
key=/home/vagrant/.ssh/id_rsa
ssh-keygen -t rsa -N "" -f $key
chown -R vagrant:vagrant /home/vagrant; chmod 600 $key; chmod 644 $key.pub

# add the vagrant keypair and open up security groups
echo "Adding keypair and creating security group rules..."
cd /home/vagrant/devstack
for user in admin demo; do
  source openrc $user $user
  nova keypair-add --pub-key $key.pub vagrant
  nova secgroup-add-rule default udp 1 65535 0.0.0.0/0
  nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
  nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
  nova secgroup-add-rule default tcp 80 80 0.0.0.0/0
  nova secgroup-add-rule default tcp 443 443 0.0.0.0/0
done

# use the google dns server as a sane default
echo "Adding DNS servers to subnets..."
sourceadmin
neutron subnet-update public-subnet --dns_nameservers list=true "#{DNS}"
neutron subnet-update private-subnet --dns_nameservers list=true "#{DNS}"
neutron subnet-list
neutron subnet-show private-subnet
neutron subnet-show public-subnet
sleep 5

# Setup web instances
echo "Setting up web instances..."
sourcedemo

# Create custom flavor for small cirros instances (id 6, 128 mb ram, 1 cpu, 1 gb disk)
nova flavor-create --is-public true m1.micro 6 64 1 1

# Spawn instances
num=1

while [ $num -le 3 ]; do

nova boot --image $(nova image-list | awk '/ cirros-0.3.4-x86_64-uec / {print $2}') --flavor 6 --nic net-id=$(neutron net-list | awk '/ private / {print $2}'),v4-fixed-ip=10.0.0.10$num --key-name vagrant node$num
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
for ip in 10.0.0.101 10.0.0.102 10.0.0.103; do
  ssh -i $key -o BatchMode=yes -o StrictHostKeyChecking=no cirros@$ip "while true; do echo -e 'HTTP/1.0 200 OK\r\n\r\n### SUCCESS ### You are connected to $ip' | sudo nc -l -p 80 ; done &"
  sleep 30
done

# Testing VIPs
echo ""
for vip in 10.0.0.100 192.168.27.100; do
  echo ""; echo "Testing $vip..."
  num=1
  while [[ num++ -lt 6 ]]; do
    ip=`curl --connect-timeout 1 http://$vip 2> /dev/null`
    echo "Testing http to $vip...returns...$ip"
  done
done

    EOF

end

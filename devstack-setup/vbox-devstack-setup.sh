#!/bin/bash
clear

# Cleanup
echo "# Cleaning up prior installs"
sudo userdel stack > /dev/null
sudo sed -i -e 's/stack ALL=(ALL) NOPASSWD: ALL//g' /etc/sudoers > /dev/null¬
sudo rm -rf /home/stack > /dev/null¬
sudo rm -rf /opt/stack > /dev/null¬
rm -rf ./stack.basrc > /dev/null¬
rm -rf ./devstack > /dev/null¬
rm -rf ./heat-templates > /dev/null¬

# Install prerequisites
echo "# Installing dependencies..."
sudo apt-get -y install git > /dev/null

# Setup stack user
echo "# Setting up stack user..."
if sudo grep stack /etc/passwd; then
        echo "Stack user already exists."
else
        sudo useradd -d /home/stack -m stack
	sudo sh -c "echo 'stack:stack' | chpasswd"
	
# Set stack.sh to run on first login (Enable to launch devstack install on login)
cat <<'EOF' > ./stack.bashrc
 
if [ -d "/opt/stack" ] ; then
    echo "Devstack installed"
else
    echo "Installing Devstack"
    cd /home/stack/devstack
    ./stack.sh
    ./post-stack.sh
    echo ""
    devstart=`head -n 1 /opt/stack/logs/stack.sh.log | awk '{ print $2 }' | cut -d . -f 1`
    devstop=`tail -n 9 /opt/stack/logs/stack.sh.log | grep 2015 | awk '{ print $2 }' | cut -d . -f 1`
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
    . openrc
fi
EOF
	sudo sh -c "cat ./stack.bashrc >> /home/stack/.bashrc"
	echo "Stack user added."
fi

echo "# Adding stack user to sudoers..."
if sudo grep stack /etc/sudoers > /dev/null; then
        echo "Stack user already in sudoers"
else
	echo "Added stack user to sudoers"
        sudo sh -c "echo 'stack ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
fi

# Create some post stack tasks
cat <<'EOF' > ./post-stack.sh

# Source credentials
cd /home/stack/devstack
. openrc

# Create ssh keys and add them
cd /home/stack
mkdir .ssh
ssh-keygen -f ./.ssh/id_rsa -t rsa -N ''
chmod 700 ~/.ssh && chmod 600 ~/.ssh/*
nova keypair-add --pub-key .ssh/id_rsa.pub mykey

# Setup security groups
neutron security-group-rule-create --protocol icmp --direction ingress default
neutron security-group-rule-create --protocol tcp --port-range-min 22 --port-range-max 22 --direction ingress default

# Create a test instance and assign a floating ip
nova boot --flavor m1.tiny --image cirros-0.3.3-x86_64-disk --key-name mykey cirros1
EOF

# Download and install devstack
git clone https://github.com/openstack-dev/devstack.git ./devstack/ > /dev/null
# Disabled temporarily to speed up test builds
# git clone https://github.com/openstack/heat-templates.git ./heat-templates/ > /dev/null

# Install and configure devstack
cat <<'EOF' > ./devstack/local.conf
[[local|localrc]]

# Global Options
LOGFILE=/opt/stack/logs/stack.sh.log
VERBOSE=True
LOG_COLOR=False
SCREEN_LOGDIR=/opt/stack/logs
LOGDAYS=1
RECLONE=yes

# Speedup DevStack Install
UBUNTU_INST_HTTP_HOSTNAME="archive.ubuntu.com"
UBUNTU_INST_HTTP_DIRECTORY="/ubuntu"

# Auth Info
ADMIN_PASSWORD=stack
DATABASE_PASSWORD=$ADMIN_PASSWORD
RABBIT_PASSWORD=$ADMIN_PASSWORD
SERVICE_PASSWORD=$ADMIN_PASSWORD
SERVICE_TOKEN=$ADMIN_PASSWORD

# Branches
KEYSTONE_BRANCH=stable/kilo
NOVA_BRANCH=stable/kilo
NEUTRON_BRANCH=stable/kilo
SWIFT_BRANCH=stable/kilo
GLANCE_BRANCH=stable/kilo
CINDER_BRANCH=stable/kilo
HEAT_BRANCH=stable/kilo
TROVE_BRANCH=stable/kilo
HORIZON_BRANCH=stable/kilo
SAHARA_BRANCH=stable/kilo

## Disable unwanted services
# Nova network and extra neutron services
disable_service n-net
disable_service q-fwaas
disable_service q-vpn
# Tempest services
disable_service tempest
# Sahara
disable_service sahara
# Trove services
disable_service trove
disable_service tr-api
disable_service tr-mgr
disable_service tr-cond
# Swift services
disable_service s-proxy
disable_service s-object
disable_service s-container
disable_service s-account

# Enable Cinder services
# Disabled temporarily to speed up test builds
# enable_service cinder
# enable_service c-api
# enable_service c-vol
# enable_service c-sch
# enable_service c-bak

# Enable Database Backend MySQL
enable_service mysql

# Enable RPC Backend RabbitMQ
enable_service rabbit

# Enable Keystone - OpenStack Identity Service
enable_service key

# Enable Horizon - OpenStack Dashboard Service
enable_service horizon

# Enable Glance -  OpenStack Image service 
enable_service g-api
enable_service g-reg

# Enable Neutron - Networking Service
enable_service q-svc
enable_service q-agt
enable_service q-dhcp
enable_service q-l3
enable_service q-meta
enable_service q-lbaas
enable_service neutron

# Neutron Options
# VLAN configuration.
PUBLIC_SUBNET_NAME=public
PRIVATE_SUBNET_NAME=private
PUBLIC_INTERFACE=eth2
FIXED_RANGE=10.16.1.0/24
FIXED_NETWORK_SIZE=256
NETWORK_GATEWAY=10.16.1.1
HOST_IP=172.16.1.15
FLOATING_RANGE=172.16.2.128/24
PUBLIC_NETWORK_GATEWAY=172.16.2.129
ENABLE_TENANT_VLANS=True
TENANT_VLAN_RANGE=3001:4000
PHYSICAL_NETWORK=default
OVS_PHYSICAL_BRIDGE=br-ex
PROVIDER_SUBNET_NAME="provider_net"
PROVIDER_NETWORK_TYPE="vlan"
SEGMENTATION_ID=2010
Q_PLUGIN=ml2
Q_USE_SECGROUP=True
Q_USE_PROVIDER_NETWORKING=True
Q_L3_ENABLED=True

# GRE tunnel configuration
# Q_PLUGIN=ml2
# ENABLE_TENANT_TUNNELS=True

# VXLAN tunnel configuration
# Q_PLUGIN=ml2
# Q_ML2_TENANT_NETWORK_TYPE=vxlan

# Enable Ceilometer - Metering Service (metering + alarming)
# Disabled temporarily to speed up test builds
# enable_service ceilometer-acompute
# enable_service ceilometer-acentral
# enable_service ceilometer-anotification
# enable_service ceilometer-api
# enable_service ceilometer-alarm-notifier
# enable_service ceilometer-alarm-evaluator

# Enable Heat - Orchestration Service
# Disabled temporarily to speed up test builds
# enable_service heat
# enable_service h-api
# enable_service h-api-cfn
# enable_service h-api-cw
# enable_service h-eng

# Images
# Disabled temporarily to speed up builds
# IMAGE_URLS="http://cloud-images.ubuntu.com/releases/14.04/release/ubuntu-14.04-server-cloudimg-amd64-disk1.img,http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img"
IMAGE_URLS="http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img"

EOF

# Add iptables forwarding rule for neutron / eth0
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Copy files and fix permissions
sudo cp -rf ./devstack /home/stack/
# sudo cp -rf ./heat-templates /home/stack/
sudo chmod +x ./post-stack.sh
sudo cp -rf ./post-stack.sh /home/stack/devstack
sudo chown -R stack:stack /home/stack/*

# Change to stack user
cd /home/stack
sudo su stack

#!/bin/bash
clear

# Cleanup
echo "# Cleaning up prior installs"
sudo userdel stack
sudo sed -i -e 's/stack ALL=(ALL) NOPASSWD: ALL//g' /etc/sudoers
sudo rm -rf /home/stack
rm -rf ./devstack
rm -rf ./heat-templates

echo ""

# Install prerequisites
echo "# Installing dependencies..."
if sudo dpkg-query -l git | grep "no package"; then
	echo "Installing git."
	sudo apt-get -y install git > /dev/null
else
	echo "All dependencies installed."
fi

echo ""

# Setup stack user
echo "# Setting up stack user..."
if sudo grep stack /etc/passwd > /dev/null; then
        echo "Stack user already exists."
else
	echo "Stack user added."
        sudo useradd -d /home/stack -m stack
	sudo sh -c "echo 'stack:stack' | chpasswd"
fi

echo ""

echo "# Adding stack user to sudoers..."
if sudo grep stack /etc/sudoers > /dev/null; then
        echo "Stack user already in sudoers"
else
	echo "Added stack user to sudoers"
        sudo sh -c "echo 'stack ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
fi

echo ""

# Download and install devstack
git clone https://github.com/openstack-dev/devstack.git ./devstack/ > /dev/null
git clone https://github.com/openstack/heat-templates.git ./heat-templates/ > /dev/null

# Install and configure devstack
cat <<'EOF' > ./devstack/local.conf
[[local|localrc]]

# Auth Info
ADMIN_PASSWORD=stack
DATABASE_PASSWORD=$ADMIN_PASSWORD
RABBIT_PASSWORD=$ADMIN_PASSWORD
SERVICE_PASSWORD=$ADMIN_PASSWORD
SERVICE_TOKEN=$ADMIN_PASSWORD

# Hard set host ip as needed in multi-nic / multi-ip configurations
# HOST_IP=172.16.80.110

# Neutron - Networking Service
disable_service n-net
ENABLED_SERVICES+=,q-svc,q-agt,q-dhcp,q-l3,q-meta,neutron

## Neutron - Load Balancing
ENABLED_SERVICES+=,q-lbaas

# Heat - Orchestration Service
ENABLED_SERVICES+=,heat,h-api,h-api-cfn,h-api-cw,h-eng

# Ceilometer - Metering Service (metering + alarming)
ENABLED_SERVICES+=,ceilometer-acompute,ceilometer-acentral,ceilometer-collector,ceilometer-api
ENABLED_SERVICES+=,ceilometer-alarm-notify,ceilometer-alarm-eval

# Images
IMAGE_URLS+=",http://fedorapeople.org/groups/heat/prebuilt-jeos-images/F19-i386-cfntools.qcow2"
IMAGE_URLS+=",http://fedorapeople.org/groups/heat/prebuilt-jeos-images/F19-x86_64-cfntools.qcow2"
IMAGE_URLS+=",http://mirror.chpc.utah.edu/pub/fedora/linux/releases/20/Images/x86_64/Fedora-x86_64-20-20131211.1-sda.qcow2"

# Output
LOGFILE=/opt/stack/logs/stack.sh.log
VERBOSE=True
LOG_COLOR=False
SCREEN_LOGDIR=/opt/stack/logs
EOF

# Copy files and fix permissions
sudo cp -rf ./devstack /home/stack/
sudo cp -rf ./heat-templates /home/stack/
sudo chown -R stack:stack /home/stack/*

# Change to stack user
cd /home/stack
sudo su stack

#!/bin/bash

# Install prerequisites
sudo apt-get -y install git

# Setup stack user
sudo adduser --disabled-password --gecos "" stack
sudo echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Download and install devstack
sudo cd /home/stack
sudo git clone https://github.com/openstack-dev/devstack.git ./devstack/
sudo git clone https://github.com/openstack/heat-templates.git ./heat-templates/
sudo chown -vR stack:stack /home/stack

# Install and configure devstack
su – stack
cat <<'EOF' > /home/stack/devstack/local.conf
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

cd /home/stack/devstack; ./stack.sh

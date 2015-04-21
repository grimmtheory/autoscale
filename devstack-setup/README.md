# autoscale/devstack-setup

## Instructions for setting up devstack for autoscale.

To download devstack and for a full devstack reference, visit http://www.devstack.org

Abbreviated setup instructions are located in this repo. These instructions assume Ubuntu 14.04.x, at least 2 CPU cores, 8 GB of disk and 4 GB of RAM. You can cut and paste these commands in manually or manually download them here:

http://www.github.com/grimmtheory/autoscale/devstack-setup/auto-devstack-setup.sh

	#!/bin/bash
	
	# Install prerequisites
	sudo apt-get -y install git
	
	# Setup stack user
	sudo adduser --disabled-password --gecos "" stack
	sudo echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
	
	# Download and install devstack
	cd /home/stack
	git clone https://github.com/openstack-dev/devstack.git ./devstack/
	git clone https://github.com/openstack/heat-templates.git ./heat-templates/
	chown -vR stack:stack /home/stack
	
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

# -*- mode: ruby -*-
# vi: set ft=ruby :

HOST_IP = "192.168.33.2"
VM_NET = "192.168.27"
DEVSTACK_BRANCH = "stable/kilo"
DEVSTACK_PASSWORD = "stack"

Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/trusty64"
  # set the hostname, otherwise qrouter will be lost upon reload
  config.vm.hostname = "devstack"
  # eth1, this will be the management endpoint
  config.vm.network :private_network, ip: "#{HOST_IP}"
  # eth2, this will be the "public" VM network
  config.vm.network :private_network, ip: "#{VM_NET}.2", netmask: "255.255.255.0", auto_config: false
  # virtual-box specific settings
  config.vm.provider :virtualbox do |vb|
    vb.gui = true
    vb.customize ["modifyvm", :id, "--memory", 4096]
    # eth2 must be in promiscuous mode for floating IPs to be accessible
    vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
  end

  config.vm.provision "shell", inline: <<-EOF
    apt-get update
    apt-get install git -y
    git clone https://github.com/openstack-dev/devstack.git /home/vagrant/devstack
    # cd /home/vagrant/devstack && git checkout -b stable/kilo origin/stable/kilo
    cd /home/vagrant/devstack
    cat << CONF > /home/vagrant/devstack/local.conf
[[local|localrc]]
HOST_IP=#{HOST_IP}
DEVSTACK_BRANCH=#{DEVSTACK_BRANCH}
DEVSTACK_PASSWORD=#{DEVSTACK_PASSWORD}

# Speedup DevStack Install, hard set mirror
UBUNTU_INST_HTTP_HOSTNAME="archive.ubuntu.com"
UBUNTU_INST_HTTP_DIRECTORY="/ubuntu"

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
LOGFILE=/home/stack/vagrant/logs/stack.sh.log

INSTANCES_PATH=/home/vagrant/instances
FLAT_INTERFACE=eth2
PUBLIC_INTERFACE=eth2

FIXED_RANGE=10.0.0.0/24
FLOATING_RANGE=#{VM_NET}.0/24
PUBLIC_NETWORK_GATEWAY=#{VM_NET}.2
Q_FLOATING_ALLOCATION_POOL=start=#{VM_NET}.3,end=#{VM_NET}.254

## Disable unwanted services
# Nova network
disable_service n-net
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

# Enable Glance - OpenStack Image Registry service 
enable_service g-api
enable_service g-reg

# Images
# IMAGE_URLS="http://cloud-images.ubuntu.com/releases/14.04/release/ubuntu-14.04-server-cloudimg-amd64-disk1.img,http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img"

# Enable Neutron
enable_service q-svc
enable_service q-agt
enable_service q-dhcp
enable_service q-l3
enable_service q-meta
enable_service q-lbaas
enable_service neutron

# Enable Ceilometer - Metering Service (metering + alarming)
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
    echo vagrant:stack | chpasswd¬

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

    # make sure eth2 comes up and br-ex is properly configured after reboot
    cat << ETH2 > /etc/network/interfaces.d/eth2.cfg
auto eth2
iface eth2 inet manual
ETH2
    cat << BREX > /etc/network/interfaces.d/br-ex.cfg
auto br-ex
iface br-ex inet static
      address #{VM_NET}.2
      netmask 255.255.255.0
      up ip route add 10.0.0.0/24 via #{VM_NET}.3 dev br-ex
BREX

    cat << POST > /home/vagrant/post.sh
cd /home/vagrant/devstack

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
source openrc admin admin
neutron subnet-update public-subnet --dns_nameservers list=true 8.8.8.8
neutron subnet-update private-subnet --dns_nameservers list=true 8.8.8.8

cd /home/vagrant/devstack
source openrc demo demo

# boot a cirros instance
nova boot --flavor m1.tiny --image cirros-0.3.2-x86_64-uec --key-name vagrant cirros
sleep 15
nova list

# assign a floating ip
fixed_ip=`nova list --name cirros | tail -n2 | head -n1 | awk '{print $12}' | awk -F= '{ print $2 }' | sed -e 's/,//g'`
device_id=`nova list --name cirros | tail -n2 | head -n1 | awk '{print $2}'`
port_id=`neutron port-list -c id -- --device_id $device_id | tail -n2 | head -n1 | awk '{print $2}'`
neutron floatingip-create --fixed-ip-address $fixed_ip --port-id $port_id public

POST

    # fix permissions as the cloned repo is owned by root
    chown -R vagrant:vagrant /home/vagrant

    # Execute post.sh
    cd /home/vagrant
    chmod +x ./post.sh
    # ./post.sh

    EOF

end

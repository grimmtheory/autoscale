#!/bin/bash
# Set verbose and set exit on error
set -v
set -e

# Set passwords
echo root:stack | chpasswd
echo vagrant:stack | chpasswd

# Populate hosts file
echo "192.168.253.129 devstack" >> /etc/hosts

# Configure network interfaces
cp /etc/network/interfaces /root/interfaces.original
cat << NETSCRIPT > /etc/network/interfaces
# The loopback network interface
auto lo
iface lo inet loopback

# Auto-configured by Vagrant, default route out / NAT
auto eth0
iface eth0 inet dhcp
pre-up sleep 2

# Management Network - Server management and all OpenStack services and API end-points
auto eth1
iface eth1 inet static
      address 192.168.253.129
      netmask 255.255.255.0

# Neutron Network - Tunnel, L3, LBaaS, DHCP, etc.
auto eth2
iface eth2 inet manual
      up ifconfig $IFACE 0.0.0.0 up
      down ifconfig  0.0.0.0 down
NETSCRIPT
cp /etc/network/interfaces /root/interfaces.modified

# Speedup boot time
sed -i -e 's/sleep/# sleep/g' /etc/init/failsafe.conf

# Install Virtual Box guest additions
apt-get -y install linux-headers-generic build-essential dkms
apt-get -y install virtualbox-guest-utils

# Download devstack setup script
wget https://raw.githubusercontent.com/grimmtheory/autoscale/master/devstack-setup/vbox-devstack-setup.sh
wget https://raw.githubusercontent.com/grimmtheory/autoscale/master/vagrant/vagrant-post.sh
wget https://raw.githubusercontent.com/grimmtheory/autoscale/master/vagrant/Vagrantfile
chmod +x ./*.sh
cp ./* /root

# Install git for devstack and some other tools
apt-get -y install git nmap traceroute

# Stage OVS stuff for Neutron
# echo 1 > /proc/sys/net/ipv4/ip_forward
# iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
# apt-get -y install openvswitch-switch
# ovs-vsctl add-br br-ex
# ovs-vsctl add-port br-ex eth1
# ovs-vsctl show

# Add some settings to sysctl and startup for networking
echo "net.ipv4.conf.eth2.proxy_arp = 1" >> /etc/sysctl.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE" >> /etc/rc.local
sysctl -p
sh -c /etc/rc.local

# Reboot
reboot

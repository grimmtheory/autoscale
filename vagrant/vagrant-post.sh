#!/bin/bash
# Set commands to pass to all VMs during build time
# $commonscript = <<COMMONSCRIPT
# Set verbose
set -v

# Set exit on error
set -e

# Set passwords
echo root:stack | chpasswd
echo vagrant:stack | chpasswd

# Populate hosts file
cat << HOSTSSCRIPT >> /etc/hosts

10.1.2.15 ubuntu1404
HOSTSSCRIPT

# Configure network interfaces
cat << NETSCRIPT > /tmp/interfaces.modified
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
      address 10.1.2.15
      netmask 255.255.255.0

# Neutron Network - Tunnel, L3, LBaaS, DHCP, etc.
auto eth2
iface eth2 inet manual
      up ifconfig $IFACE 0.0.0.0 up
      down ifconfig  0.0.0.0 down
NETSCRIPT

cp /etc/network/interfaces /root/interfaces.original
cp /tmp/interfaces.modified /root/interfaces.modified
cp /tmp/interfaces.modified /etc/network/interfaces

# Speedup boot time
sed -i -e 's/sleep/# sleep/g' /etc/init/failsafe.conf

# Speedup installs, enable local ISO / CD repo
# mount -a
# mount -t iso9660 -o loop /mnt/vagrant/ubuntu-14.04.2-server-amd64-full.iso /media/cdrom
# echo "mount -t iso9660 -o loop /mnt/vagrant/ubuntu-14.04.2-server-amd64-full.iso /media/cdrom" >> /etc/rc.local
# cp /etc/apt/sources.list /etc/apt/sources.original
# echo "deb file:/media/cdrom trusty main restricted" >> /etc/apt/sources.list
# apt-get -y update

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
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
apt-get -y install openvswitch-switch
ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex eth1
ovs-vsctl show

# Add some settings to sysctl and startup for networking
echo "net.ipv4.conf.eth0.proxy_arp = 1" >> /etc/sysctl.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE" >> /etc/rc.local
sysctl -p
sh -c /etc/rc.local

# Reboot
reboot
# COMMONSCRIPT
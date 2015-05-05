# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.synced_folder "./", "/vagrant", disabled: true

  config.vm.provider "virtualbox" do |vb|

    vb.gui = true
    vb.memory = "4096"
    vb.cpus = "2"
    vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]

  end

  config.vm.define "devstack" do |devstack_config|

    devstack_config.vm.box = "ubuntu/trusty64"
    # devstack_config.vm.hostname = “devstack”

    devstack_config.vm.network "private_network", ip: "192.168.254.10"
    devstack_config.vm.network "private_network", ip: "172.16.254.10"

    devstack_config.vm.provision "shell", privileged: true, inline: <<-SHELL

      #!/usr/bin/env bash

      apt-get update
      apt-get -y upgrade
      apt-get -y install git

      git clone https://github.com/openstack-dev/devstack.git ./devstack/

      wget https://raw.githubusercontent.com/grimmtheory/autoscale/master/bashrc /home/vagrant/bashrc
      cat /home/vagrant/bashrc >> /home/vagrant/.bashrc; rm -rf /home/vagrant/bashrc
      wget https://raw.githubusercontent.com/grimmtheory/autoscale/master/local.conf /home/vagrant/devstack/local.conf
      wget https://raw.githubusercontent.com/grimmtheory/autoscale/master/interfaces /etc/network/interfaces

      echo "net.ipv4.conf.eth2.proxy_arp = 1" >> /etc/sysctl.conf
      echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
      echo "iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE" >> /etc/rc.local
      sysctl -p
      sh -c /etc/rc.local

      sed -i -e 's/sleep/# sleep/g' /etc/init/failsafe.conf

      chown -R vagrant:vagrant /home/vagrant

      reboot

    SHELL

  end

end

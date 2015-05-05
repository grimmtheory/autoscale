# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  # config.vm.box = "base"
  config.vm.box = "ubuntu/trusty64"

  config.vm.hostname = “devstack”
  config.vm.network "private_network", ip: "192.168.254.10"
  config.vm.network "private_network", ip: "172.16.254.10"

  config.vm.provider "virtualbox" do |vb|

    vb.gui = true
    vb.memory = "4096"
    vb.cpus = "2"
    vb.name = "devstack"
    vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]

  end

  config.vm.provision "shell", privileged: false, inline: <<-SHELL

    #!/usr/bin/env bash

    sudo apt-get update
    sudo apt-get -y upgrade
    sudo apt-get -y install git

    sudo git clone https://github.com/openstack-dev/devstack.git ./devstack/

    sudo wget https://raw.githubusercontent.com/grimmtheory/autoscale/master/bashrc ~/
    cat ~/bashrc >> ~/.bashrc; rm -rf ~/bashrc
    sudo wget https://raw.githubusercontent.com/grimmtheory/autoscale/master/local.conf ~/devstack
    sudo wget https://raw.githubusercontent.com/grimmtheory/autoscale/master/interfaces /etc/network/interfaces

    reboot

  SHELL

end

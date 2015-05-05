# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.synced_folder "./", "/vagrant", disabled: true

  config.vm.define "autostack" do |autostack_config|

    autostack_config.vm.box = "ubuntu/trusty64"
    autostack_config.vm.hostname = “autostack”

    autostack_config.vm.network "private_network", ip: "192.168.254.10"
    autostack_config.vm.network "private_network", ip: "172.16.254.10"

    autostack_config.vm.provider "virtualbox" do |vb|

      vb.gui = true
      vb.memory = "4096"
      vb.cpus = "2"
      vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]

    end

    autostack_config.vm.provision "shell", privileged: false, inline: <<-SHELL

      #!/usr/bin/env bash

      sudo apt-get update
      sudo apt-get -y upgrade
      sudo apt-get -y install git

      sudo git clone https://github.com/openstack-dev/autostack.git ./autostack/

      sudo wget https://raw.githubusercontent.com/grimmtheory/autoscale/master/bashrc ~/
      sudo cat ~/bashrc >> ~/.bashrc; sudo rm -rf ~/bashrc
      sudo wget https://raw.githubusercontent.com/grimmtheory/autoscale/master/local.conf ~/autostack
      sudo wget https://raw.githubusercontent.com/grimmtheory/autoscale/master/interfaces /etc/network/interfaces

      reboot

    SHELL

  end

end

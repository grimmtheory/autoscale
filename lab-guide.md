# OpenStack Autoscale Lab Guide

Version 0.1, Kilo Stable Release, April 26, 2015

This guide is Open Source under the Apache 2.0 License Agreement and only uses or makes reference to other Free and Open Source Software.

The purpose of this guide is to assist a user with setting up and becoming familiar with OpenStack Autoscale utilizing core / native OpenStack services - Keystone, Nova, Heat, Ceilometer, etc.

The guide is broken down into the following sections:

* Test Environment Setup
* Basic Functional Testing
* Basic Heat Operations
* Advanced Heat Operations Setup
* Advanced Heat Operations

## Test Environment Setup

This section contains the procedures for building a suitable test environment for OpenStack Autoscale operations.  Much of the tedious steps of environment setup have been taken care of, however expanded instructions are also provided where possible if a manual or alternate configuration is desired.

### Downloading The Tools

For ease of use and automation we will be utilizing Virtual Box aided by Vagrant for our test machine setup.

#### Step 1 - Download and install Virtual Box

For Mac, Linux or Windows users, if you wish to use a desktop UI, you can open a browser, go to [Virtual Box](https://www.virtualbox.org/wiki/Downloads), select Mac, Windows, or Linux as appropriate, download the disk image (.exe, .rpm or .deb as necessary), double click on the downloaded file and follow the instructions.

Alternately, you can do this useing the CLI by opening a terminal and entering the following:

On Mac:

	cd ~
	wget http://download.virtualbox.org/virtualbox/4.3.26/VirtualBox-4.3.26-98988-OSX.dmg
	hdiutil attach ~/VirtualBox-4.3.26-98988-OSX.dmg
	sudo installer -pkg /Volumes/VirtualBox/VirtualBox.pkg -target /Volumes/Macintosh\ HD

On CentOS (or most other RPM-based systems):

	sudo cd /etc/yum.repos.d
	sudo wget http://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo
	sudo yum --enablerepo rpmforge install dkms
	sudo yum groupinstall "Development Tools"
	sudo yum install kernel-devel
	sudo yum install VirtualBox

On Ubuntu (or most other Debian-based systems):

	sudo sh -c "echo 'deb http://download.virtualbox.org/virtualbox/debian \
	'$(lsb_release -cs)' contrib non-free' > /etc/apt/sources.list.d/virtualbox.list" && \
	wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | sudo \
	apt-key add - && sudo apt-get update && sudo apt-get install virtualbox-4.3 dkms

#### Step 2 - Download and install Vagrant

For Mac, Linux or Windows users, if you wish to use a desktop UI, you can open a browser, go to [Vagrant](http://www.vagrantup.com/downloads.html), select Mac, Windows, or Linux as appropriate, download the disk image (.exe, .rpm or .deb as necessary), double click on the downloaded file and follow the instructions.

Alternately, you can do this useing the CLI by opening a terminal and entering the following:

On Mac:

	cd ~
	wget https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2.dmg
	hdiutil attach ~/https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2.dmg
	sudo installer -pkg /Volumes/VirtualBox/Vagrant.pkg -target /Volumes/Macintosh\ HD

On CentOS (or most other RPM-based systems):

	sudo yum install ruby
	sudo yum install rubygems
	sudo gem update --system
	sudo gem install vagrant

On Ubuntu (or most other Debian-based systems):

	sudo apt-get install vagrant

### Installing The Test Machine

#### Manual Method

If you want set your test machine manually follow these steps:

1. Download the Ubuntu 14.04.2 LTS Server 64-bit ISO from [here](http://releases.ubuntu.com/14.04.2/ubuntu-14.04.2-server-amd64.iso)
2. Launch Virtual Box and create a virtual machine
3. Set the machine type to Linux - Ubuntu
4. Set the vCPU count to at least 2
5. Set the RAM size to at least 2 GB
6. Set the disk size to at least 8 GB
7. Set the number of NICs to 2 and configure them to be bridged to the same network
8. Mount the downloaded ISO into the virtual cdrom
9. Boot the virtual machine and accept all installation defaults

#### Automated Method

This method utilizes Vagrant to automate nearly all of our setup tasks.  The downloading and running of the Vagrant file is only a couple of steps, but we'll spend some time here describing how this process works.

Download the Vagrant file

	cd ~
	wget https://github.com/grimmtheory/autoscale/blob/master/vagrant/Vagrantfile

Launch the Vagrant file

	vagrant init
	vagrant up

The Vagrant file has been heavily commented so you can see what each section is doing.  The latest version is included here for reference.

This section is the default header for the type of work we'll be doing using Virtual Box:

	# -*- mode: ruby -*-
	# vi: set ft=ruby :
	
	VAGRANTFILE_API_VERSION = "2"
	ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

	Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|


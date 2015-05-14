# Autoscale environment build and setup
To support build, test and development efforts around OpenStack in general, and specifically autoscale configurations here, we have created a toolset for the detailed configuration and then rapid deployment of test virtual machines.

## Methodology
This build automation leverages vagrant 2.3.2, virtualbox 4.3.28, ubuntu 14.04.x and openstack kilo (stable).

In short vagrant drives the majority of the automation of the environment build process.  When looking at the tool chain you'll see some snips of BASH, YAML, python, etc. which isn't Vagrant-based Ruby, but Vagrant calls on all of these snips (many have been isolated in the tools directory) to perform all of the provisioning, configuration management, etc. tasks and at the end of the day it starts and ends all builds and is therefore at the top of the tool chain.  A summary of these steps is as follows:

* Vagrant provisions the VirtualBox virtual machine(s) including detailed settings required for openstack, e.g. vt acceleration, nic count and type, promiscuous mode, etc.  During that process it:

	* Configures virtual hardware; current configuration default for the stable build is:
		* 1 vCPU, 4 GB of RAM
		* VT-x and APIC-IO disabled
			* I should have gotten a performance boost out of these settings, however it seemed to cause inconsistent results.  Everything runs fine without it, at least for single / all-in-one environment builds; I may enable for multi-vm builds after I have more time to test and measure performance results.
		* Network adapters configured:
			* eth0 = NAT / default Vagrant network - Provides default route out as well as Vagrant management access (default dhcp ip 10.0.2.15) 
			* eth1 = Host-Only network - Provide host OS management as well as OpenStack API end-point access / binding (static ip 192.168.33.2/24)
			* eth2 = Host-Only network - "Unconfigured" by Vagrant, dedicated to Neutron OVS operations (initially set to manual 0.0.0.0 and then later during the OpenStack prep portion it is bound to virtual device "br-ex"static ip 192.168.27.2/24)
	* After the hardware is configured it downloads the latest "ubuntu/trusty64" image and boots the virtual machine with it.
	* Once the machine is booted the default adapter is configured in the host OS, ssh keys are injected, the machine is named within the OS and any stock Vagrant settings for the image type are configured, e.g. sysctl settings for NAT / masquerade forwarding, etc.
	* During this process it also handles a few housekeeping items around how VirtualBox behaves, e.g. vb.gui = true, VirtualBox machine name, etc.
	* Note - I experimented with vagrant-proxyconf, vagrant-cachier and other tools to try and speed up build times and had some success but not enough to justify leaving the configuration in the stable build.  You can see some of these options and snips in the tools folder.  It's not that the plugins did not work as intended, it was more that proxying and / or caching ssl is a pain and all of the gpg key exchange and other security constraints associated with github, ubuntu apt package signing, etc.

## Build Versions and Build Types
Even though there is only 1 Vagrantfile in this folder it actually supports a total of 6 different build types.  This includes Base, Staged and Complete build types for both "stable" and "dev" versions of the tool.  If you look in the header of Vagrantfile you will see 2 variables where you can set both the *Build "Type"* and the *Build "Verstion"*, shown here:

	BUILD_TYPE="COMPLETE" # Set to BASE, STAGED or COMPLETE based on your build need
	BUILD_VERSION="STABLE" # Set to STABLE or DEV based on your build purpose

### Build Versions
The intent of the *STABLE* and *DEV* build versions is as one might expect.  For the versions:

#### Stable
The *Stable* build type would generally be used for working with **consistent and "stable"** functions and features (of Ubuntu, DevStack, Vagrant, VirtualBox, etc.).  These "known good" configurations are helpful when you are testing new concepts, e.g. Trove, Sahara, etc.
#### Dev (Development)
The *Dev* build type would generally be used for **developing or testing** new features and functionality within an existing stack, e.g. adding automatic creation of Heat templates as part of the *Complete* build type.

### Build Types
For the *BASE*, *STAGED* and *COMPLETE* build types, the purpose of each is as follows:
#### Base
The purpose of the *BASE* build environment is to provide HW and OS installed and configured that is prepared for an OpenStack installation but does not actually have anything installed on it yet.  This includes the HW and OS setup along with networking (including staging OVS), cloned gitstack repos, local.conf configured, updates installed, etc.  The purpose being that if you wanted a quick build ready for install but want to make some changes to networking, local.conf, etc. before an install occurs then you could use this build would allow you to do that.  The second use case, and my own personal interest, is for training and demo, i.e. use the OpenStack-ready build and then walk through the other steps by hand.
#### Staged
The *STAGED* build is the same as the *BASE* build with the exception that Devstack has been installed, however no OpenStack "post-install" tasks have been executed.
#### Complete
Like the *STAGED* build, the *COMPLETE* build type is an amalgamation of the prior build types.  In addition to the tasks of the base and staging processes, the complete build process also adds several DevStack / OpenStack post-installation tasks.  This "post-install" set of commands and scripts is not Vagrant, VirtualBox or DevStack dependent and should work on any native / open OpenStack build that has the same services installed and of the same release.

## Build Tasks
A mostly complete list of the more important build tasks provided by each build type is as follows:

| Build Version    | Build Type                | Build Task                                                                                         |
|------------------|:--------------------------|:---------------------------------------------------------------------------------------------------|
| Stable and Dev   | Base, Staged and Complete | Provision and configure virtual hardware                                                           |
| Stable and Dev   | Base, Staged and Complete | Download, install and configure operating system                                                   |
| Dev              | Base, Staged and Complete | HW / HTTP acceleration - proxy, cache, VT-x, APIC-IO                                               |
| Dev              | Base, Staged and Complete | OS Acceleration - sysctl tuning, TCP buffer, I/O scheduler                                         |
| Dev              | Base, Staged and Complete | Public bridged adapter option, defaults to wifi nic                                                |
| Stable and Dev   | Staged and Complete       | Apt update and dependencies installed                                                              |
| Stable and Dev   | Staged and Complete       | Git clone DevStack, Autoscale, Heat-Templates, etc.                                                |
| Stable and Dev   | Staged and Complete       | Generate users and keys, add default key to Nova                                                   |
| Stable and Dev   | Staged and Complete       | Modify default security group - add ICMP, 22, 80 and 443                                           |
| Stable and Dev   | Staged and Complete       | Add DNS to default public- and private-subnet                                                      |
| Stable and Dev   | Staged and Complete       | Create a custom flavor, m1.micro - 1 vCPU x 32 MB RAM x 1 GB Disk                                  |
| Stable and Dev   | Complete                  | Spawn 3 VMs - cirros, m1.micro, static ip / name 10.0.0.101(2,3) / name node1(2,3), key, etc.      |
| Stable and Dev   | Complete                  | Create a load-balancer pool - pool1, connected to private-net, HTTP, round-robin                   |
| Stable and Dev   | Complete                  | Create 3 load-balancer pool members - node1(2,3), protocol port 80 and add them to pool1           |
| Stable and Dev   | Complete                  | Create a load-balancer health monitor - service HTTP, delay 3, retry 3, timeout 3                  |
| Stable and Dev   | Complete                  | Associate the new load-balancer health monitor to pool1                                            |
| Stable and Dev   | Complete                  | Create a load-balancer VIP - 10.0.0.100, port 80, protocol HTTP and attach to private network      |
| Stable and Dev   | Complete                  | Create a load-balancer floating-ip - 192.168.27.100 > 10.0.0.100                                   |
| Stable and Dev   | Complete                  | Create a "listener" on members - while...netcat...80 (no apache in cirros but works great for test)|
| Stable and Dev   | Complete                  | Test and verify - while...for vip in $publicnet.100 $privatenet.100; do curl http://$vip...done    |

## Build Flow

## Build Testing and Troubleshooting

Will be finished by jtg later...


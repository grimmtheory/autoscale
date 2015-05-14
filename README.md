# autoscale environment build and setup
To support build, test and development efforts around OpenStack in general, and specifically autoscale configurations here, we have created a toolset for the detailed configuration and then rapid deployment of test virtual machines.

## Methodology
This build automation leverages vagrant 2.3.2, virtualbox 4.3.28, ubuntu 14.04.x and openstack kilo (stable).

In short vagrant drives the automation of the environment builds.  virtualbox virtual machines, including detailed settings required for openstack, e.g. vt acceleration, nic count and type, promiscuous mode, etc. 

## build types
You'll see there are seveal folders here, the purpose of each is as follows:
* bas

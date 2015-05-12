#!/bin/bash

# Source credentials
source /home/vagrant/devstack/openrc admin demo

# Set variables
outputfile=`echo ${0##*/} | sed -e 's/.sh//g'`.yaml

key=vagrant
flavor=m1.tiny
image=cirros-0.3.4-x86_64-uec
node_name=stacknode

private_network=`neutron net-list | grep -v ipv6 | grep private | awk '{ print $2 }'`
private_subnet=`neutron subnet-list | grep -v ipv6 | grep private | awk '{ print $2 }'`

public_network=`neutron net-list | grep -v ipv6 | grep public | awk '{ print $2 }'`
public_subnet=`neutron subnet-list | grep -v ipv6 | grep public | awk '{ print $2 }'`

# Create template
cat << HOT > $outputfile
heat_template_version: 2013-05-23
parameters:
  key_name:
    type: string
    default: $key
  node_name:
    type: string
    default: $node_name
  node_server_flavor:
    type: string
    default: $flavor
  node_image_name:
    type: string
    default: $image
  floating_net_id:
    type: string
    default: $public_network
  private_net_id:
    type: string
    default: $private_network
  private_subnet_id:
    type: string
    default: $private_subnet

resources:

  vm_port:
    type: OS::Neutron::Port
    properties:
      network_id: { get_param: private_net_id }
      fixed_ips:
        - subnet_id: { get_param: private_subnet_id }

  vm_floating_ip:
    type: OS::Neutron::FloatingIP
    properties:
      floating_network_id: { get_param: floating_net_id }
      port_id: { get_resource: vm_port }

  vm_instance:
    type: OS::Nova::Server
    properties:
      name: { get_param: node_name }
      image: { get_param: node_image_name }
      flavor: { get_param: node_server_flavor }
      key_name: { get_param: key_name }
      networks:
        - port: { get_resource: vm_port }
HOT
cat $outputfile

#!/bin/bash

# Source credentials
source /home/vagrant/devstack/openrc admin demo

# Set variables
outputfile=`echo ${0##*/} | sed -e 's/.sh//g'`.yaml
for object in public private; do
  $objectnetwork=`neutron net-list | grep $object | awk '{ print $2 }'`
  echo "$objectnetwork guid = $objectnetwork"
  $objectsubnet=`neutron subnet-list | grep $object | awk '{ print $2 }'`
  echo "$objectsubnet guid = $objectsubnet"
done

# Create template
cat << HOT > $outputfile
heat_template_version: 2013-05-23
parameters:
  key_name:
    type: string
    default: vm_key
  node_name:
    type: string
    default: lb-vm
  node_server_flavor:
    type: string
    default: m1.tiny
  node_image_name:
    type: string
    default: cirros-0.3.4-x86_64-uec
  floating_net_id:
    type: string
    default: $publicnetwork
  private_net_id:
    type: string
    default: $privatenetwork
  private_subnet_id:
    type: string
    default: $privatesubnet

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

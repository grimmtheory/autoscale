====================
Lab Exercises
==============

The purpose of these labs is to facilitate understanding of fundamental components involved in building a simple heat template to more advanced ones such as instanting load balancers and autoscaling VM instances based on ceilometer alarms. 

Pre-reqs:

* Pre-installed and enabled heat services.
* Tenants and users created
* nova keypairs uploaded
* An externally routable network to serve as floating network
* An internal network for fixed ips

Lab 1:
------
The objective of this lab is to launch a server using a hot template.  
The simple-server.yaml itself comprises of a hot template that takes in parameters as required -

- Spawn a customized VM
- Insert the ssh keypair
- Create requisite security groups
- Create a VM port, assign a fixed ip from the internal network and apply the security group rules
- Create a floating ip on the external network and associcate it with the fixed ip
- Setup user-data to create a script to simulate HTTP responses

Usage:

```
heat stack-create simple-stack -f simple-scale.yaml -e environment.yaml --parameters \
"key_name=<key_name>\
;node_name=<node_name>\
;node_server_flavor=<node_server_flavor>\
;node_image_name=<node_image_name>;\
;floating_net_id=<floating_net_id>;\
;private_net_id=<private_net_id>;\
;private_subnet_id=<private_subnet_id>"
```

Result:
- run heat stack-list to ensure state is COMPLETE
- Run heat stack-show simple-stack
The default group's desired state is 2 VM instances, so a nova list should show 2 new instances created.
Perform a curl -X GET http:<floating-ip-of-vm> for each of the VMs and verify it returns the internal network ip address of the VM.

Clean up the stack in preparation for the next lab

```
heat stack-delete simple-stack
```

Lab 2:
------
This lab has 2 parts to it.  As one of the first steps it will

Part 1:

- create and configure load balancer pool with a ROUND_ROBIN policy over http protocol.
- create a health monitor and associate it with the lb pool created above
- create a vip from the internal subnet and assign it to the lb pool
- create a floating ip and associate it with the vip of the lb pool

Usage:

```
heat stack-create load-balancer.yaml --parameters \
"floating_net_id=<floating_net_id>\
; "private_subnet_id=<private_subnet_id>"
```

Result: Verify the relevant resources get created.

```
- heat stack-list to ensure state is COMPLETE
- neutron lb-list
- neutron lb-pool-show <name of pool from above>
- neutron lb-healthmonitor-list
- neutron lb-vip-list
- neutron lb-vip-show <lb-vip-instance-id-from-above>
- neutron floatingip-list | grep <address field from the output from lb-vip-show>
```

The floatingip should be pingable.  A ```curl -X GET http://<floating-vip>``` should yeild a "503 Service Not Available" message

Part 2:

- In the subsequent part of this lab, a VM pair will be spawned as part of the resource group
- Each of the VMs will be added as loadbalanced members of the pool created above. 
- Note the additional parameter provided to this template will be the pool id from the resource created above.

The ha-servers.yaml hot template leverages the OS::Nova::Server::Scaled resource type declared in environment.yaml

```
resource_registry:
    "OS::Nova::Server::Scaled": "scaled-server.yaml"
```

Usage:

```
heat stack-create ha-servers -f ha-servers.yaml -e environment.yaml --parameters \
"key_name=<key_name>\
;node_name=<node_name>\
;node_server_flavor=<node_server_flavor>\
;node_image_name=<node_image_name>;\
;floating_net_id=<floating_net_id>;\
;private_net_id=<private_net_id>;\
;private_subnet_id=<private_subnet_id>;\
;pool_id=<pool_id>\
;initial_capacity=<initial-number-of-members>"
```

Result:  

- run heat stack-list to ensure state is COMPLETE
- Verify that the VMs are active and pingable via their individual floating ips.
- Perform a ```curl -X GET http://<floating-vip>``` and watch the IP addresses alternate between the 2 VMs

Clean up the stack in preparation for the next lab

```
heat stack-delete ha-stack
```

Lab 3:
------

This lab will build on top of Lab 2 where in when the connection rate on the LB'd VMs crosses a pre-defined threshhold, a VM will automatically be spawned and added to the load balanced pool.

# schoksey - to continue here
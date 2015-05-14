====================
Lab Exercises
==============

The purpose of these labs is to facilitate understanding of fundamental components involved in building a simple heat template to more advanced ones such as instanting load balancers and autoscaling VM instances based on ceilometer alarms. 

Pre-reqs:

* Pre-installed and enabled heat services.
* Tenants and users created
* Nova keypairs uploaded
* An externally routable network to serve as floating network
* An internal network for fixed ips

#Lab 1:

The objective of this lab is to launch a server using a hot template.  
The simple-server.yaml itself comprises of a hot template that takes in parameters as required and -

- Spawn a customized VM
- Injects an ssh key
- Creates requisite security groups
- Creates a VM port, assigns a fixed ip from the internal network and applies security group rules
- Creates a floating ip on the external network and associcates it with the fixed ip
- Installs a simulated http server via the cloud-init user-data script 

Usage:

```
heat stack-create simple-stack -f simple-server.yaml --parameters \
"key_name=<key_name>\
;node_name=<node_name>\
;node_server_flavor=<node_server_flavor>\
;node_image_name=<node_image_name>;\
;floating_net_id=<floating_net_id>;\
;private_net_id=<private_net_id>;\
;private_subnet_id=<private_subnet_id>"
```

Verification:

- Run ```heat stack-list``` to ensure stack is in CREATE_COMPLETE state
- Run ```heat stack-show simple-stack```
- Run ```nova list``` should display the VM created as a result of the stack creation
- Perform a ```curl -X GET http://<floating-ip-of-vm>``` and ensure it returns the ipaddress of the VM on the private network.
- The output should look like ```You are connected to <fixed-ipaddress>```
- Ssh into the VM ```ssh -i <ssh-key-file> cirros@<floating-ipaddress>```

Clean up the stack in preparation for the next lab

```
heat stack-delete simple-stack
```

# Lab 2:

This a two-part lab.

Part 1:
-------
- Creates and configures a load balancer pool with ROUND_ROBIN policy over http.
- Createss a health monitor and associates it with the loadbalancer pool
- Creates a vip from the internal subnet and assigns it to the loadbalancer pool
- Creates a floating ip and associates it with the vip of the loadbalancer pool

Usage:

```
heat stack-create loadbalacer-stack load-balancer.yaml --parameters \
"floating_net_id=<floating_net_id>\
;"private_subnet_id=<private_subnet_id>"
```

Result: Verify the relevant resources get created.


- Run ```heat stack-list``` to ensure stack is in CREATE_COMPLETE state
- Run the following to discover resources created

```
neutron lb-list
neutron lb-pool-show <name of pool from above>
neutron lb-healthmonitor-list
neutron lb-vip-list
neutron lb-vip-show <lb-vip-instance-id-from-above>
neutron floatingip-list | grep <address field from the output from lb-vip-show>
```
- The floatingip vip should be pingable ```ping <floating-vip>```
- A ```curl -X GET http://<floating-vip>``` should response with ```503 Service Not Available``` message

Part 2:
-------
- In the subsequent part of this lab, a VM pair by default or an initial number of members as specified in the initial_capacity parameter will be spawned as part of the resource group
- Each of the VMs will be added as loadbalanced members of the pool created above. 
- Note the additional parameter provided to this template will be the pool id from the resource created above.

The ha-servers.yaml hot template leverages the ```OS::Nova::Server::Scaled``` resource type declared in environment.yaml

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
;initial_capacity=<initial-number-of-members>\
;asg_group_min_size=<asg_group_min_size>\
;asg_group_max_size=<asg_group_max_size>"
```

Verification:  

- A ```heat stack-list``` to ensure stack is in CREATE_COMPLETE state
- A ```nova list``` should display an equal number of newly created VMs as configured in the ```initial_capacity``` parameter as a result of the stack creation
- Verify that the VMs are active and pingable via their individual floating ips.
- Perform a ```curl -X GET http://<floating-ip-of-vm>``` on each of the VMs to ensure it returns the ipaddress of the VM on the private network.
- The output should look like ```You are connected to <fixed-ipaddress>```
- Perform a ```curl -X GET http://<floating-vip>``` and watch the private IP addresses alternate between the VMs as the requests get load balanced in a round robin policy

Clean up the stack in preparation for the next lab.
```
heat stack-delete ha-stack
```

*NOTE: Do not delete the ```loadbalacer-stack```*



#Lab 3:

This lab will build on top of Lab 2 where in -

- A member pool will be created with N number of VMs as specified in the ```initial_capacity```
- Using the ab tool (ApacheBench) a load for an arbritrary number of concurrent requests will be generated against the ```floating-vip```
- When the connection rate on the load balanced VMs crosses a pre-defined threshhold  for a given evaluation period, a VM will automatically be spawned and added to the load balanced pool.

# schoksey - to continue here
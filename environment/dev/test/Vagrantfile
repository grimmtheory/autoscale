# -*- mode: ruby -*-
# vi: set ft=ruby :

# Some global settings for devstack local.conf

# Set build type and version
BUILD_TYPE="COMPLETE" # Set build type to "BASE", "STAGED" or "COMPLETE" based on your build need
BUILD_VERSION="DEV" # Set build version to "STABLE" or "DEV" to enable or disable experimental features

# Set OS config
OS_HOSTNAME = "DEVSTACK-#{BUILD_VERSION}-#{BUILD_TYPE}" # Hostname for the OS, defaults to devstack + build version + build type
VAHOME = "/home/vagrant" # Vagrant home directory
NIC3_PROMISCUOUS = "true" # Leave true for Neutron flat / bridged configurations

# Proxy config
PROXY = "false" # Proxy server on or off
HTTP_PROXY_HOST = "http://192.168.34.1" # Proxy host if enabled
HTTPS_PROXY_PORT = "8888" # Proxy port if proxy host is enabled
HTTPS_PROXY_HOST = "http://192.168.34.1" # Proxy host if enabled
HTTP_PROXY_PORT = "8888" # Proxy port if proxy host is enabled

# Host OS image config
VB_IMAGE_SOURCE = "" # Set to either "" to use the default Hashicorp syntax, "ubuntu/trusty64", or "URL" to use url syntax, http://cloud-images.ubuntu.com/vagrant/trusty...
VB_IMAGE_NAME = "ubuntu/trusty64" # The latest VirtualBox image of Trusty server 64 bit from Ubuntu
VB_IMAGE_URL = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box" # Populate if you are pulling your own image

# Set network config
MANAGEMENT_NETWORK = "192.168.34" # Management network
PUBLIC_NETWORK = "192.168.28" # Neutron gateway / provider network
PRIVATE_NETWORK = "10.0.0" # Private network CIDR
DEFAULT_MASK = "255.255.255.0" # Defualt /24 network mask unless specified otherwise
DNS = "10.0.2.3" # Default DNS server for your subnets, e.g. local VirtualBox forwarder

# Set OpenStack base config
HOST_IP = "#{MANAGEMENT_NETWORK}.2" # Management IP, ssh to the OS, OpenStack APIs, etc.
DEVSTACK_BRANCH = "stable/kilo" # Devstack branch to synch to, defaults to "master"
DEVSTACK_PASSWORD = "stack" # Password for all devstack services and logins

# Set OpenStack image / flavor config
DEFAULT_NOVA_IMAGE = "cirros-0.3.4-x86_64-uec" # Used for all instance builds unless specified otherwise
DEFAULT_NOVA_FLAVOR_NAME = "m1.micro" # Default is 1, m1.tiny, set to custom flavor - 1 vcpu x 64 mb ram x 1 gb disk
DEFAULT_NOVA_FLAVOR_ID = "6" # Default is 1, m1.tiny, currently set to a custom flavor built during install, 6

# Set OpenStack neutron config, get OpenStack neutron guids
FLAT_NEUTRON_INTERFACE = "eth2" # Interface that Neutron bridges to, don't change this unless you understand the impact
PUBLIC_NEUTRON_INTERFACE = "eth2" # Interface that Neutron routes and nats through, don't change this unless you understand the impact
PUBLIC_NETWORK_NAME = "public-network" # What to name the public network
PUBLIC_SUBNET_NAME = "public-subnet" # Give the public subnet a name, defaults to "public-subnet"
PRIVATE_NETWORK_NAME = "private-network" # What to name the public network
PRIVATE_SUBNET_NAME = "private-subnet" # Give the public subnet a name, defaults to "public-subnet"

# Set OpenStack security config
SSH_KEY_NAME = "vagrant" # Name of the nova keypair that will be created
SSH_KEY_PATH = "#{VAHOME}/.ssh/id_rsa" # Private key location of the key generated for the nova keypair
SECURITY_GROUP_NAME = "default" # Name of the security group to add rules to
SECURITY_GROUP_RULES = "22 80 443" # List of ports to open up in the default security group

# Set Openstack load balancer config
LBPOOL_NAME = "lbpool1" # Name your load balancer pool
LBPOOL_PORT = "80" # Load balancer port
LBPOOL_PROTOCOL = "HTTP" # Load balancer port
PRIVATE_NETWORK_VIP = "#{PRIVATE_NETWORK}.100" # Defaults to .100 on the private network
PRIVATE_NETWORK_VIP_NAME = "vip-#{PRIVATE_NETWORK_VIP}" # Defaults to "vip-" + "vip ip address"
PUBLIC_NETWORK_VIP = "#{PUBLIC_NETWORK}.100" # Defaults to .100 on the private network

# VirtualBox config
VB_HOSTNAME = "#{OS_HOSTNAME}" # Hostname label within VirtualBox, defaults to matching the OS_HOSTNAME
CPU = "1" # Number of virtual CPUs, 1 seems to run faster than 2 as VirtualBox is a hypervisor that runs in userland, i.e. poor virtual SMP
RAM = "4096" # System memory
VT_X = "false" # Intel / AMD VT acceleration, inconsistent performance when testing with this build
APIC_IO = "false" # Network IO acceleration, inconsistent performance when testing with this build

##################################################################################
#    DO NOT MAKE ANY CHANGES BELOW THIS LINE UNLESS YOU UNDERSTAND THE IMPACT    #
##################################################################################

Vagrant.configure("2") do |config|

  # Select distribution and build for the box
  if "#{VB_IMAGE_SOURCE}" == "URL"
    config.vm.url = "#{VB_IMAGE_URL}"
  else
    config.vm.box = "#{VB_IMAGE_NAME}"
  end

  if "#{PROXY}" == "true"
    if Vagrant.has_plugin?("vagrant-proxyconf")
      config.proxy.http     = "#{HTTP_PROXY_HOST}:#{HTTP_PROXY_PORT}/"
      config.proxy.https    = "#{HTTPS_PROXY_HOST}:#{HTTPS_PROXY_PORT}/"
      config.proxy.no_proxy = "localhost,127.0.0.1,.example.com"
    end
  end

  # Speed up https downloads
  config.vm.box_download_insecure = "true"

  # set the hostname, otherwise qrouter will be lost upon reload
  config.vm.hostname = "#{OS_HOSTNAME}"

  # eth1, this will be the management endpoint
  config.vm.network :private_network, ip: "#{HOST_IP}", netmask: "#{DEFAULT_MASK}"

  # eth2, this will be the "public" VM network
  config.vm.network :private_network, ip: "#{PUBLIC_NETWORK}.2", netmask: "#{DEFAULT_MASK}", auto_config: false

  # virtual-box specific settings
  config.vm.provider :virtualbox do |vb|

    # Lable the virtual machine
    vb.name = "#{VB_HOSTNAME}"

    # Enable the Virtual Box GUI on boot, i.e. not "headless"
    vb.gui = true

    # Set CPU and memoru size
    vb.customize ["modifyvm", :id, "--cpus", "#{CPU}"]
    vb.customize ["modifyvm", :id, "--memory", "#{RAM}"]

    # Enable promiscuous mode on eth2 for floating IPs to be accessible
    if "#{NIC3_PROMISCUOUS}" == "true"
      vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
    end

  end

  if "#{BUILD_TYPE}" != "STABLE"
    # Suppress tty messages
    config.vm.provision "fix-no-tty", type: "shell" do |s|
      s.privileged = false
      s.inline = "sudo sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile"
    end

    # Begin in-line script
    config.vm.provision "shell", inline: <<-EOF

    EOF

    # Install git
    apt-get update
    apt-get -y install git

    # Clone the devstack repo
    git clone https://github.com/openstack-dev/devstack.git "#{VAHOME}/devstack"

    # Clone the heat-templates repo
    git clone https://github.com/openstack/heat-templates.git "#{VAHOME}/heat-templates"

    # Clone the autoscale repo
    git clone https://github.com/grimmtheory/autoscale.git "#{VAHOME}/autoscale"

    # Configure devstack
    cd "#{VAHOME}/devstack"
    cat << CONF > "#{VAHOME}/devstack/local.conf"
    CONF

    [[local|localrc]]
    HOST_IP=#{HOST_IP}
      DEVSTACK_BRANCH=#{DEVSTACK_BRANCH}
      DEVSTACK_PASSWORD=#{DEVSTACK_PASSWORD}

      # Extra config options
      # EXTRA_OPTS=(metadata_host=#{HOST_IP})
      # Q_DHCP_EXTRA_DEFAULT_OPTS=(enable_metadata_network=True enable_isolated_metadata=True)

      # Disable ipv6
      # IP_VERSION=4

      # Set branch for services
      KEYSTONE_BRANCH=#{DEVSTACK_BRANCH}
      NOVA_BRANCH=#{DEVSTACK_BRANCH}
      PUBLIC_BRANCH=#{DEVSTACK_BRANCH}
      GLANCE_BRANCH=#{DEVSTACK_BRANCH}
      CINDER_BRANCH=#{DEVSTACK_BRANCH}
      HEAT_BRANCH=#{DEVSTACK_BRANCH}
      HORIZON_BRANCH=#{DEVSTACK_BRANCH}

      # Default passwords
      ADMIN_PASSWORD=#{DEVSTACK_PASSWORD}
      MYSQL_PASSWORD=#{DEVSTACK_PASSWORD}
      RABBIT_PASSWORD=#{DEVSTACK_PASSWORD}
      SERVICE_PASSWORD=#{DEVSTACK_PASSWORD}
      SERVICE_TOKEN=#{DEVSTACK_PASSWORD}

      SCREEN_LOGDIR="/opt/stack/logs"
    LOGFILE="#{VAHOME}/devstack/logs/stack.sh.log"
    INSTANCES_PATH="#{VAHOME}/instances"

    # Disable unwanted services
    # Disable nova network
    disable_service n-net
    # Disable tempest
    disable_service tempest
    # Disable sahara
    disable_service sahara
    # Disable trove
    disable_service trove
    disable_service tr-api
    disable_service tr-mgr
    disable_service tr-cond
    # Disable swift
    disable_service s-proxy
    disable_service s-object
    disable_service s-container
    disable_service s-account
    # Disable cinder
    disable_service cinder
    disable_service c-api
    disable_service c-vol
    disable_service c-sch
    disable_service c-bak

    # Enable Cinder services
    # enable_service cinder
    # enable_service c-api
    # enable_service c-vol
    # enable_service c-sch
    # enable_service c-bak

    # Configure Cinder services
    # VOLUME_GROUP="stack-volumes"
    # VOLUME_NAME_PREFIX="volume-"
    # VOLUME_BACKING_FILE_SIZE=250M

    # Enable Database Backend MySQL
    enable_service mysql

    # Enable RPC Backend RabbitMQ
    enable_service rabbit

    # Enable Keystone - OpenStack Identity Service
    enable_service key

    # Enable Horizon - OpenStack Dashboard Service
    enable_service horizon

    # Enable Glance - OpenStack Image Registry service
    enable_service g-api
    enable_service g-reg

    # Enable Neutron
    enable_service q-svc
    enable_service q-agt
    enable_service q-dhcp
    enable_service q-l3
    enable_service q-meta
    enable_service q-lbaas
    enable_service neutron

    # Configure Neutron
    FLAT_INTERFACE="#{FLAT_NEUTRON_INTERFACE}"
    PUBLIC_INTERFACE="#{PUBLIC_NEUTRON_INTERFACE}"
    FIXED_RANGE="#{PRIVATE_NETWORK}.0/24"
    FLOATING_RANGE="#{PUBLIC_NETWORK}.0/24"
    PUBLIC_NETWORK_GATEWAY="#{PUBLIC_NETWORK}.2"
    Q_FLOATING_ALLOCATION_POOL="start='#{PUBLIC_NETWORK}.3,end=#{PUBLIC_NETWORK}.254'"

    # Enable Ceilometer - Metering Service (metering + alarming)
    enable_service ceilometer-collector
    enable_service ceilometer-acompute
    enable_service ceilometer-acentral
    enable_service ceilometer-anotification
    enable_service ceilometer-api
    enable_service ceilometer-alarm-notifier
    enable_service ceilometer-alarm-evaluator

    # Enable Heat - Orchestration Service
    enable_service heat
    enable_service h-api
    enable_service h-api-cfn
    enable_service h-api-cw
    enable_service h-eng
    CONF

    # Set passwords
    echo "" ; echo "Setting passwords..."
    echo root:stack | chpasswd
    echo vagrant:stack | chpasswd

    # fix permissions as the cloned repo is owned by root
    echo "" ; echo "Updating permissions on "#{VAHOME}"..."
    chown -R vagrant:vagrant "#{VAHOME}"

    # Add credentials to Vagrant's bash profile
    echo "" ; echo "Adding openrc credentials to '#{VAHOME}/.bash_profile'"
    echo "source '#{VAHOME}/devstack/openrc admin demo' >> '#{VAHOME}/.bash_profile'"

    # fix routing so that VMs can reach out to the internets
    echo "" ; echo "Fixing routing so that "#{PRIVATE_NETWORK}.0/24" can see "#{PUBLIC_NETWORK}.0/24"
    cat << SYSCTL > "/etc/sysctl.d/60-devstack.conf"
    net.ipv4.conf.eth0.proxy_arp = 1
    net.ipv4.ip_forward = 1
    SYSCTL

    echo "" ; echo "Applying new routing, interface rules, etc."
    sysctl --system
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

    # bring up eth2
    echo "" ; echo "Bringing up eth2..."
    ip link set dev eth2 up
    echo "" ; echo "Bringing up eth2 results:"
    echo "" ; ifconfig eth2

    # setup devstack
    echo "" ; "Setting up DevStack..."
    cd "#{VAHOME}/devstack"
    sudo -u vagrant env HOME=#{VAHOME} ./stack.sh

      # fix network setup to make VMs pingable from inside and outside devstack
      echo "" ; echo "Fix network setup to make VMs pingable from inside and outside devstack"
    ovs-vsctl add-port br-ex eth2

    # Setup the eth2 interfaces file
    cat << ETH2 > "/etc/network/interfaces.d/eth2.cfg"
    auto eth2
    iface eth2 inet manual
    ETH2

    # Setup the br-ex interfaces file
    cat << BREX > "/etc/network/interfaces.d/br-ex.cfg"
    auto br-ex
    iface br-ex inet static
    address "#{PUBLIC_NETWORK}.2"
    netmask "#{DEFAULT_MASK}"
    up ip route add "#{PRIVATE_NETWORK}.0/24" via "#{PUBLIC_NETWORK}.3" dev br-ex
    BREX

    # Begin post tasks
    cd "#{VAHOME}"

    # Report stack.sh run time - Stack.sh used to report run time, since they've removed that add it back
    devstart=`head -n 1 "#{VAHOME}/devstack/logs/stack.sh.log" | awk '{ print $2 }' | cut -d . -f 1`
    devstop=`tail -n 9 "#{VAHOME}/devstack/logs/stack.sh.log" | grep -m1 2015 | awk '{ print $2 }' | cut -d . -f 1`
    startdate=$(date -u -d "$devstart" +"%s")
    enddate=$(date -u -d "$devstop" +"%s")
    runtime=`date -u -d "0 $enddate sec - $startdate sec" +"%H:%M:%S"`

    echo " -----------------------------"
    echo " | DEVSTACK START:  $devstart |"
    echo " | DEVSTACK STOP:   $devstop |"
    echo " -----------------------------"
    echo " | TOTAL RUN TIME:  $runtime |"
    echo " -----------------------------"
    echo ""

    # Source credential functions to allow easy swapping between creds as needed
    sourceadmin () { echo "Sourcing user admin and project admin..."; source "#{VAHOME}/devstack/openrc" admin admin; }
    sourcedemo () { echo "Sourcing user admin and project demo..."; source "#{VAHOME}/devstack/openrc" admin demo; }

    sourceadmin

    # Setup local variables
    PUBLIC_NETWORK_ID = `neutron net-list | grep -v ipv6 | grep public | awk '{ print $2 }'` # Public network guid
    PUBLIC_SUBNET_ID = `neutron subnet-list | grep -v ipv6 | grep public | awk '{ print $2 }'` # Public subnet guid
    PRIVATE_NETWORK_ID = `neutron net-list | grep -v ipv6 | grep private | awk '{ print $2 }'` # Private network guid
    PRIVATE_SUBNET_ID = `neutron subnet-list | grep -v ipv6 | grep private | awk '{ print $2 }'` # Private subnet guid

    # generate a keypair and make it available via share
    echo "Generating keypair for key name: #{SSH_KEY_NAME}"
    ssh-keygen -t rsa -N "" -f "#{SSH_KEY_PATH}"
    chown -R vagrant:vagrant "#{VAHOME}" ; chmod 600 "#{SSH_KEY_PATH}" ; chmod 644 "#{SSH_KEY_PATH}.pub"

    # add the vagrant keypair and open up security groups
    echo "Adding keypair and creating security group rules..."
    cd "#{VAHOME}/devstack"
    for user in admin demo; do

        # Source OpenStack credentials and add keypair
        source openrc $user $user
        nova keypair-add --pub-key "#{SSH_KEY_PATH}.pub" "#{SSH_KEY_NAME}"

        # Allow for UDP and ICMP
        nova secgroup-add-rule default udp 1 65535 0.0.0.0/0
        nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0

        # Add TCP rules
        for port in `echo "#{SECURITY_GROUP_RULES}"` ; do
            nova secgroup-add-rule "#{SECURITY_GROUP_NAME}" tcp $port $port 0.0.0.0/0
            done
            done

            echo "" ; echo "Security group rules and keypair creation output:"
            echo "" ; nova secgroup-list-rules default
            echo "" ; nova keypair-list

            # use the google dns server as a sane default
            echo "Adding DNS servers to subnets..."
            sourceadmin
            neutron subnet-update "#{PUBLIC_SUBNET_NAME}" --dns_nameservers list=true "#{DNS}"
            neutron subnet-update "#{PRIVATE_SUBNET_NAME}" --dns_nameservers list=true "#{DNS}"
            echo "" ; echo "Neutron subnet configuration output:"
            echo "" ; neutron subnet-list ; neutron subnet-show "#{PUBLIC_SUBNET_NAME}" ; neutron subnet-show "#{PUBLIC_SUBNET_NAME}"
            echo "" ; echo "Sleeping 5 seconds..." ; sleep 5

            # Setup web instances
            echo "Setting up web instances..."
            sourcedemo

            # Create a custom flavor for small cirros instances (id 6, 128 mb ram, 1 cpu, 1 gb disk)
            echo "" ; echo "Creating custom flavor '#{DEFAULT_NOVA_FLAVOR_NAME}' for web instances..."
            echo "" ; nova flavor-create --is-public true "#{DEFAULT_NOVA_FLAVOR_NAME}" 6 64 1 1
            echo "" ; echo "Custom flavor creation output:"
            echo "" ; nova flavor-list ; nova flavor-show "#{DEFAULT_NOVA_FLAVOR_NAME}"
            echo "" ; echo "Sleeping 5 seconds..." ; sleep 5

            # Spawn instances
            echo "" ; echo "Spawning instances..."
            num=1

            while [ $num -le 3 ] ; do

                echo "Creating instance node$num..."
                echo "nova boot --image '#{DEFAULT_NOVA_IMAGE}' --flavor '#{DEFAULT_NOVA_FLAVOR_ID}' --nic net-id='$PRIVATE_NETWORK_ID,v4-fixed-ip='#{PRIVATE_NETWORK}'.10$num --key-name '#{SSH_KEY_NAME}' node$num"
                nova boot --image "#{DEFAULT_NOVA_IMAGE}" --flavor "#{DEFAULT_NOVA_FLAVOR_ID}" --nic net-id="$PRIVATE_NETWORK_ID",v4-fixed-ip=#{PRIVATE_NETWORK}.10$num --key-name "#{SSH_KEY_NAME}" node$num
                  echo "" ; echo "Sleeping 5 seconds..." ; sleep 30

                echo "" ; echo "instance node$num created:"
                echo "" ; nova show node$num

                num=$(( $num + 1 ))

                done

                echo "" ; echo "All instances created."
                echo "" ; nova list

                # Create load balancer pool
                echo "Creating load balancer pool..."
                sourcedemo
                echo "neutron lb-pool-create --lb-method ROUND_ROBIN --name "#{LBPOOL_NAME}" --protocol "#{LBPOOL_PROTOCOL}" --subnet-id $PRIVATE_SUBNET_ID"
                neutron lb-pool-create --lb-method ROUND_ROBIN --name "#{LBPOOL_NAME}" --protocol "#{LBPOOL_PROTOCOL}" --subnet-id $PRIVATE_SUBNET_ID
                echo "" ; echo "Load balancer pool creation complete:"
                neutron lb-pool-list
                echo "" ; echo "Sleeping 10 seconds..." ; sleep 10

                # Add load balancer members
                echo "Adding load balancer pool members..."
                sourcedemo
                num=1
                while [ $num -le 3 ]; do

                    echo "Adding member node$num to load balancer pool..."
                    echo "neutron lb-member-create --address "#{PRIVATE_NETWORK}.10$num" --protocol-port "#{LBPOOL_PORT}" "#{LBPOOL_NAME}""

                    neutron lb-member-create --address "#{PRIVATE_NETWORK}.10$num" --protocol-port "#{LBPOOL_PORT}" "#{LBPOOL_NAME}"

                    echo "" ; echo "Load balancer pool member $num added."
                    echo "" ; echo "Sleeping 3 seconds..." ; sleep 3
                    num=$(( $num + 1 ))

                    done

                    echo "" ; echo "All load balancer members added to "#{LBPOOL_NAME}"."
                    neutron lb-member-list
                    echo "" ; echo "Sleeping 5 seconds..." ; sleep 5

                    # Setup load balancer health monitor
                    sourcedemo

                    echo "Creating load balancer health monitor..."
                    echo "neutron lb-healthmonitor-create --delay 3 --type "#{LBPOOL_PROTOCOL}" --max-retries 3 --timeout 3"
                    neutron lb-healthmonitor-create --delay 3 --type "#{LBPOOL_PROTOCOL}" --max-retries 3 --timeout 3

                    echo "Associating health monitor..."
                    echo "healthmonitorid=`neutron lb-healthmonitor-list | grep "#{LBPOOL_PROTOCOL}" | awk '{ print $2 }'`"

                    healthmonitorid=`neutron lb-healthmonitor-list | grep "#{LBPOOL_PROTOCOL}" | awk '{ print $2 }'`
                    echo "neutron lb-healthmonitor-associate $healthmonitorid" "#{LBPOOL_NAME}""
neutron lb-healthmonitor-associate $healthmonitorid" "#{LBPOOL_NAME}"

                    echo "" ; echo "Health monitor added to "#{LBPOOL_NAME}"."
                    echo "" ; echo "Sleeping 5 seconds..." ; sleep 5
                    neutron lb-healthmonitor-list

                    # Create load balancer vip
                    echo "Creating load balancer vip..."
                    sourcedemo

                    echo "neutron lb-vip-create --name "#{PRIVATE_NETWORK_VIP_NAME} --protocol-port "#{LBPOOL_PORT}" --protocol "#{LBPOOL_PROTOCOL}" --subnet-id $PRIVATE_SUBNET_ID --address "#{PRIVATE_NETWORK_VIP}" "#{LBPOOL_NAME}""
                    neutron lb-vip-create --name "#{PRIVATE_NETWORK_VIP_NAME} --protocol-port "#{LBPOOL_PORT}" --protocol "#{LBPOOL_PROTOCOL}" --subnet-id $PRIVATE_SUBNET_ID --address "#{PRIVATE_NETWORK_VIP}" "#{LBPOOL_NAME}"

                    echo "" ; echo "Load balancer vip creation complete:"
                    echo "" ; neutron lb-vip-list
                    echo "" ; echo "Sleeping 5 seconds..." ; sleep 5

                    # Add load balancer floating ip
                    echo "Adding floating ip to load balancer..."
                    sourcedemo

                    echo "neutron floatingip-create --port-id $portid --fixed-ip-address "#{PRIVATE_NETWORK_VIP}" --floating-ip-address "#{PUBLIC_NETWORK_VIP}" public"
                    portid=`neutron port-list | grep "#{PRIVATE_NETWORK_VIP}" | awk '{ print $2 }'`
                    neutron floatingip-create --port-id $portid --fixed-ip-address "#{PRIVATE_NETWORK_VIP}" --floating-ip-address "#{PUBLIC_NETWORK_VIP}" public

                    echo "" ; echo "Sleeping 5 seconds..." ; sleep 5
                    neutron floatingip-list

                    # Turn on an http listener for each host
                    echo "Creating an HTTP listener on each node..."

                    for ip in "#{PRIVATE_NETWORK}.101" "#{PRIVATE_NETWORK}.102" "#{PRIVATE_NETWORK}.103"; do

                        echo "Creating listener on $ip ..."
                        ssh -i "#{SSH_KEY_PATH}" -o BatchMode=yes -o StrictHostKeyChecking=no cirros@$ip "while true; do echo -e 'HTTP/1.0 200 OK\r\n\r\nYou are connected to $ip' | sudo nc -l -p 80 ; done &"
                        echo "" ; echo "Sleeping 5 seconds..." ; sleep 5

                        done

                        echo "All listeners created."
                        echo "" ; echo "Sleeping 5 seconds..." ; sleep 5


                        # Testing VIPs
                        echo "Testing the HTTP listener on each node..."

                        for ip in "#{PRIVATE_NETWORK}.101" "#{PRIVATE_NETWORK}.102" "#{PRIVATE_NETWORK}.103" ; do

                            echo ""
                            echo "Testing port 80 on $ip..."
                            num=1
                            while [[ num++ -lt 3 ]]; do
                                result=`curl --connect-timeout 1 http://$ip 2> /dev/null`
                                echo "Testing HTTP access to $ip...returns...$result"
                                done

                                done


                                for vip in "#{PRIVATE_NETWORK_VIP}" "#{PUBLIC_NETWORK_VIP}" ; do

                                    echo ""
                                    echo "Testing $vip..."
                                    num=1
                                    while [[ num++ -lt 6 ]]; do
                                        result=`curl --connect-timeout 1 http://$vip 2> /dev/null`
                                        echo "Testing HTTP access to $vip...returns...$result"
                                        done

                                        done

                                        EOF

                                      end

                                    end

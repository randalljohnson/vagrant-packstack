#!/bin/bash
set -e
set -x

# Set these to IP/Gateway of Packstack VM
export PACKSTACK_IP_ADDR=10.1.0.10
export PACKSTACK_IP_GW=10.1.0.1

# Configures networking daemons & installs packstack binaries
sudo systemctl disable firewalld
sudo systemctl stop firewalld
sudo systemctl disable NetworkManager
sudo systemctl stop NetworkManager
sudo systemctl enable network
sudo systemctl start network
sudo yum install -y centos-release-openstack-rocky
sudo yum install -y openstack-packstack

# Generates answer file, updates IP and runs installer binary
sudo packstack --provision-demo=n --os-neutron-ovs-bridge-mappings=extnet:br-ex --os-neutron-ovs-bridge-interfaces=br-ex:enp0s8 --os-neutron-ml2-type-drivers=vxlan,flat,vlan --gen-answer-file=packstack-answers.txt
sudo sed -i -e "s:10.0.2.15:$PACKSTACK_IP_ADDR:" packstack-answers.txt
sudo packstack --answer-file=packstack-answers.txt

# Configures br-ex interface for bridging of Openstack public network with external host network

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-br-ex
DEVICE=br-ex
DEVICETYPE=ovs
TYPE=OVSBridge
BOOTPROTO=static
IPADDR=$PACKSTACK_IP_ADDR
NETMASK=255.255.255.0
GATEWAY=$PACKSTACK_IP_GW
DNS1=8.8.8.8
ONBOOT=yes
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-enp0s8
DEVICE=enp0s8
TYPE=OVSPort
DEVICETYPE=ovs
OVS_BRIDGE=br-ex
ONBOOT=yes
EOF

ifdown enp0s8 br-ex
ifup enp0s8 br-ex
ip addr add ${PACKSTACK_IP_ADDR}/24 dev br-ex
ip link set br-ex up
#service network restart
systemctl restart neutron-openvswitch-agent neutron-server

## Set up example network & VM in the admin project ###

# Set up basic public and private networks
export PUBLIC_SUBNET=/24
export PUBLIC_NETWORK=172.16.0.0$PUBLIC_SUBNET
export PUBLIC_GW=172.16.0.1
export PUBLIC_ADDR_BEGIN=172.16.0.128
export PUBLIC_ADDR_END=172.16.0.160
export PRIVATE_SUBNET=/24
export PRIVATE_NETWORK=10.10.10.0$PRIVATE_SUBNET

. keystonerc_admin
neutron net-create public_network --provider:network_type flat \
  --provider:physical_network extnet --router:external --shared
neutron subnet-create --name public_subnet --enable_dhcp=False \
  --allocation-pool=start=$PUBLIC_ADDR_BEGIN,end=$PUBLIC_ADDR_END \
  --gateway=$PUBLIC_GW public_network $PUBLIC_NETWORK \
  --dns-nameservers list=true 8.8.8.8 4.2.2.2
neutron net-create private_network
neutron subnet-create --name private_subnet private_network $PRIVATE_NETWORK --dns-nameserver 8.8.8.8
neutron router-create router1
neutron router-gateway-set router1 public_network
neutron router-interface-add router1 private_subnet

# Import test Cirros image
curl http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img | glance \
  image-create --name='cirros' --container-format=bare --disk-format=qcow2

# Configure default security group to allow SSH & ICMP traffic
export ADMIN_PROJECT=$(openstack project list | grep admin | cut -d' ' -f2)
export DEFAULT_SECURITY_GROUP=$(openstack security group list | grep $ADMIN_PROJECT | cut -d' ' -f2)
openstack security group rule create --ingress --protocol icmp $DEFAULT_SECURITY_GROUP
openstack security group rule create --ingress --protocol tcp --dst-port 22:22 --remote-ip 0.0.0.0/0 $DEFAULT_SECURITY_GROUP
openstack security group rule create --egress --protocol tcp --dst-port 22:22 --remote-ip 0.0.0.0/0 $DEFAULT_SECURITY_GROUP

# Create keypair
openstack keypair create --public-key=~/.ssh/id_rsa.pub node1

# Launch VM
export PRIVATE_NETWORK_ID=$(openstack network list | grep private | cut -d' ' -f2)
openstack server create --image="cirros" --flavor=m1.tiny \
  --key-name=node1 --nic net-id="$PRIVATE_NETWORK_ID" \
  My_instance

# Add floating ip to test VM
export PUBLIC_NETWORK_ID=$(openstack network list | grep public | cut -d' ' -f2)
openstack floating ip create $PUBLIC_NETWORK_ID
export ADMIN_PROJECT=$(openstack project list | grep admin | cut -d' ' -f2)
export SERVER_NAME=$(openstack server list | grep cirros | cut -d' ' -f4)
export FLOATING_IP=$(openstack floating ip list | grep $ADMIN_PROJECT | cut -d' ' -f4)
openstack server add floating ip $SERVER_NAME $FLOATING_IP

# Point default GW in root namespace to to router
export ROUTER_NAMESPACE=$(ip netns | grep qrouter | cut -d' ' -f1)
ip netns exec $ROUTER_NAMESPACE ip route del default || :
ip netns exec $ROUTER_NAMESPACE ip route add default via $PUBLIC_GW

# Add route in root namespace to point to child namespace
ip route add $PUBLIC_NETWORK dev br-ex
ip addr add $PUBLIC_GW$PUBLIC_SUBNET dev br-ex

# Enable forwarding on VM kernel
sysctl -w net.ipv4.ip_forward=1

# Disable 'REJECT' iptables target that was configured by Packstack installer
iptables -t filter -D FORWARD 3

# Enable iptables masquerade rule to allow egress traffic
iptables -t nat -A POSTROUTING -s $PUBLIC_NETWORK -j MASQUERADE

#!/bin/bash
set -e
set -x

## Set up example network & VM in the admin project ###

export PACKSTACK_IP_ADDR=10.1.0.10
export PACKSTACK_IP_GW=10.1.0.1
export PUBLIC_SUBNET=/24
export PUBLIC_NETWORK=172.16.0.0$PUBLIC_SUBNET
export PUBLIC_GW=172.16.0.1
export PUBLIC_ADDR_BEGIN=172.16.0.128
export PUBLIC_ADDR_END=172.16.0.160
export PRIVATE_SUBNET=/24
export PRIVATE_NETWORK=10.10.10.0$PRIVATE_SUBNET

# Set up basic public and private networks
. /root/keystonerc_admin
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


# Add routing table entry to bridge root namespace and Packstack router namespace
ip addr add $PUBLIC_GW dev br-ex
ip route add $PUBLIC_NETWORK dev br-ex

# Point default GW in root namespace to to router
export ROUTER_NAMESPACE=$(ip netns | grep qrouter | cut -d' ' -f1)
ip netns exec $ROUTER_NAMESPACE ip route del default || :
ip netns exec $ROUTER_NAMESPACE ip route add default via $PUBLIC_GW

# Enable forwarding on VM kernel
sysctl -w net.ipv4.ip_forward=1

# Disable 'REJECT' iptables target that was configured by Packstack installer
iptables -t filter -D FORWARD 3

# Enable iptables masquerade rule to allow egress traffic
iptables -t nat -A POSTROUTING -s $PUBLIC_NETWORK -j MASQUERADE

# Show server and floating IPs
openstack server list
openstack floating ip list

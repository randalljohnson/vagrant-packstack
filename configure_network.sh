#!/bin/bash
set -e
set -x

export PACKSTACK_IP_ADDR=10.1.0.10
export PACKSTACK_IP_GW=10.1.0.1
export PUBLIC_SUBNET=/24
export PUBLIC_NETWORK=172.16.0.0$PUBLIC_SUBNET
export PUBLIC_GW=172.16.0.1
export PUBLIC_ADDR_BEGIN=172.16.0.128
export PUBLIC_ADDR_END=172.16.0.160
export PRIVATE_SUBNET=/24
export PRIVATE_NETWORK=10.10.10.0$PRIVATE_SUBNET

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

service network restart
systemctl restart neutron-openvswitch-agent neutron-server


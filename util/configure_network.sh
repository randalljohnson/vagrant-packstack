!/bin/bash
set -e
set -x

# Source network variables
. /vagrant/util/network_variables

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

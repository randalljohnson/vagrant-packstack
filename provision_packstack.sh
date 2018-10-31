#!/bin/bash
set -e
set -x

# Source network variables
. /vagrant/network_variables

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

# Set admin password to 'openstack'
export OLD_ADMIN_PW=$(cat keystonerc_admin | grep OS_PASSWORD | cut -d"'" -f2)
openstack user password set --password openstack --original-password $OLD_ADMIN_PW
echo "export OS_PASSWORD='openstack'" >> keystonerc_admin

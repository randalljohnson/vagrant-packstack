#!/bin/bash
set -e

# Remove existing instance and start a new one
vagrant destroy -f
vagrant up

# Configure networking and restart network daemons
vagrant ssh -c 'sudo /vagrant/util/configure_network.sh'
vagrant ssh -c 'sudo service network restart' || :
sleep 2
vagrant ssh -c 'sudo systemctl restart neutron-openvswitch-agent neutron-server' 

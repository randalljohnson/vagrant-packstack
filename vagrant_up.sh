#!/bin/bash
set -e

# Start new instance
vagrant up

# Configure networking and restart network daemons
vagrant ssh -c 'sudo /vagrant/util/configure_network.sh'
vagrant ssh -c 'sudo service network restart' || :
sleep 2
vagrant ssh -c 'sudo systemctl restart neutron-openvswitch-agent neutron-server' 

#!/bin/bash
set -e
vagrant destroy -f
vagrant up
vagrant ssh -c 'sudo /vagrant/util/configure_network.sh'
vagrant ssh -c 'sudo service network restart' || :
sleep 2
vagrant ssh -c 'sudo systemctl restart neutron-openvswitch-agent neutron-server' 

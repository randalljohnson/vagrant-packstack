#!/bin/bash
#set -e
#set -x
#vagrant destroy -f
#vagrant up
vagrant ssh -c 'sudo /vagrant/provision.sh'

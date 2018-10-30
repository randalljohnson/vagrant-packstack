#!/bin/bash
#set -e
#set -x
vagrant up
vagrant ssh -c 'sudo /vagrant/install.sh'

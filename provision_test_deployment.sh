#!/bin/bash
set -e
vagrant ssh -c 'sudo /vagrant/util/test_deployment.sh'

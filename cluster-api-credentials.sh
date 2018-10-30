#!/bin/bash
set -e
set -x

. /root/keystonerc_admin
openstack user list
openstack domain list
openstack project list
openstack region list
cat /root/keystonerc_admin

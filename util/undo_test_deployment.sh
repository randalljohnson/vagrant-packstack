#!/bin/bash
set -e

. /root/keystonerc_admin
export ADMIN_PROJECT=$(openstack project list | grep admin | cut -d' ' -f2)
openstack project purge --project $ADMIN_PROJECT --keep-project
neutron purge $ADMIN_PROJECT
openstack keypair delete node1 || : # Force return rc 0 if keypair does not exist

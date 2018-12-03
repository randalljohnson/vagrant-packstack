#!/bin/bash
vagrant global-status --prune
sudo "/Library/Application Support/VirtualBox/LaunchDaemons/VirtualBoxStartup.sh" restart

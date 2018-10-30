# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.box = "packstack-centos/7"

  machines = {
    'node1.example.dd'    => { :ip => '10.1.0.10'},
   #'node2.example.dd'    => { :ip =>'10.1.0.12'},
  }

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.manage_guest = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true

  config.ssh.pty = true
  config.ssh.insert_key = false

  machines.each do | hostname, attrs|
    config.vm.define hostname do |machine|
      machine.vm.hostname = hostname
      machine.vm.network :private_network, :ip => attrs[:ip]
      machine.vm.synced_folder '.', '/vagrant'

      machine.vm.provider "virtualbox" do | v |
        v.memory = "8192"
        v.cpus = "2"
        v.customize "post-boot", ["controlvm", :id, "nicpromisc2", "allow-all"]
      end
    end
  end
end

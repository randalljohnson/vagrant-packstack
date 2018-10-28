# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.box = "centos/7"

  machines = {
    'node1.example.dd'    => { :ip => '10.1.0.10'},
  #  'node2.example.dd'    => { :ip =>'10.1.0.12'},
  }

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.manage_guest = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true

  config.ssh.pty = true

  machines.each do | hostname, attrs|
    config.vm.define hostname do |machine|
      machine.vm.hostname = hostname
      machine.vm.network :private_network, :ip => attrs[:ip]
      #machine.vm.network "public_network", :bridge => 'eno1', :ip => attrs[:ip]
      machine.vm.synced_folder '.', '/vagrant', disabled: true

      machine.vm.provider "virtualbox" do | v |
        v.memory = "5120"
        v.cpus = "2"
      end

    end
  end
end

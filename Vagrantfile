# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  # Build Server connects to this host to perform deployment
  config.vm.define 'target' do |target|
    target.vm.provision 'shell', path: 'automation/remote/capabilities.sh'
    target.vm.provision 'shell', inline: 'sudo nmcli connection reload'
    target.vm.provision 'shell', inline: 'sudo systemctl restart network.service'
    target.vm.provision 'shell', path: 'automation/provisioning/addUser.sh', args: 'deployer'
    target.vm.provision 'shell', path: 'automation/provisioning/mkDirWithOwner.sh', args: '/opt/packages deployer'
    target.vm.provision 'shell', path: 'automation/remote/capabilities.sh'
    # Oracle VirtualBox with private NAT has insecure deployer keys for desktop testing
    target.vm.provider 'virtualbox' do |virtualbox, override|
      override.vm.network 'private_network', ip: '172.16.17.102'
      override.vm.box = 'cdaf/CentOSLVM'
      override.vm.network 'forwarded_port', guest: 22, host: 20022
      override.vm.network 'forwarded_port', guest: 80, host: 20080
      override.vm.provision 'shell', path: 'automation/provisioning/deployer.sh', args: 'target'
    end
    # Microsoft Hyper-V does not support NAT or setting hostname. vagrant up target --provider hyperv
    target.vm.provider 'hyperv' do |hyperv, override|
      override.vm.box = 'cdaf/CentOSLVM'
    end
  end
  
  # Build Server, fills the role of the build agent and delivers to the host above
  config.vm.define 'build' do |build|  
    build.vm.provision 'shell', path: 'automation/remote/capabilities.sh'
    build.vm.provision 'shell', inline: 'sudo nmcli connection reload'
    build.vm.provision 'shell', inline: 'sudo systemctl restart network.service'
    # Oracle VirtualBox with private NAT has insecure deployer keys for desktop testing
    build.vm.provider 'virtualbox' do |virtualbox, override|
      override.vm.network 'private_network', ip: '172.16.17.101'
      override.vm.box = 'cdaf/CentOSLVM'
      override.vm.network 'forwarded_port', guest: 22, host: 10022
      override.vm.provision 'shell', path: 'automation/provisioning/addHOSTS.sh', args: '172.16.17.102 target.sky.net'
      override.vm.provision 'shell', path: 'automation/provisioning/setenv.sh', args: 'environmentDelivery VAGRANT'
      override.vm.provision 'shell', path: 'automation/provisioning/deployer.sh', args: 'server' # Install Insecure preshared key for desktop testing
      override.vm.provision 'shell', path: 'automation/provisioning/internalCA.sh'
      override.vm.provision 'shell', path: 'automation/provisioning/CDAF.sh', privileged: false
    end
    # Microsoft Hyper-V does not support NAT or setting hostname. vagrant up build --provider hyperv
    build.vm.provider 'hyperv' do |hyperv, override|
      override.vm.box = 'cdaf/CentOSLVM'
    end
  end

end

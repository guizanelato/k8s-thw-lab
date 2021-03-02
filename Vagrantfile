# -*- mode: ruby -*-
# vi: set ft=ruby :

nodes_per_type = 3

vms = {
  'manager' => {
			'memory' => '1024', 
			'cpus' => 2,
			'ip' => 0, 
			'box' => 'geerlingguy/debian10', 
			'provision' => 'manager.sh'
			},
   'woker-node' => {
      'memory' => '1024',
      'cpus' => 2,
      'ip' => 50,
      'box' => 'geerlingguy/debian10',
      'provision' => 'worker-node.sh'		
	}
}

Vagrant.configure('2') do |config|

  config.vm.box_check_update = false
  config.vm.provision "file", source: "./provision/scripts", destination:"/home/vagrant/scripts"
  
  (1..nodes_per_type).each do |i|
    vms.each do |name, conf|
	  config.vm.define "#{name}-0#{i}" do |my|
        my.vm.box = conf['box']
        my.vm.hostname = "#{name}-0#{i}"
        my.vm.network 'private_network', ip: "172.20.12.#{conf['ip'] + (10 * i)}"
        my.vm.provision 'shell', path: "provision/#{conf['provision']}"
		my.vm.provider 'virtualbox' do |vb|
		 vb.memory = conf['memory']
		 vb.name = "k8s_#{name}_0#{i}"
		 vb.cpus = conf['cpus']
		end
      end
    end
  end
end


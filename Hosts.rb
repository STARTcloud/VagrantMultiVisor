# coding: utf-8

# This class takes the Hosts.yaml and set's the neccessary variables to run provider specific sequences to boot a VM.
class Hosts
  def Hosts.configure(config, settings)

    ## Load your Secrets file
    secrets = YAML::load(File.read("#{File.dirname(__FILE__)}/.secrets.yml")) if File.exists?("#{File.dirname(__FILE__)}/.secrets.yml")
    # Main loop to configure VM
    settings['hosts'].each_with_index do |host, index|
      provider = host['provider-type']

      config.vm.define "#{host['partition_id']}--#{host['subdomain']}.#{host['domain']}" do |server|

        #Box Settings -- Used in downloading and packaging Vagrant boxes
        server.vm.box = host['box'] 
        if settings.has_key?('boxes')
          boxes = settings['boxes']
          if boxes.has_key?(server.vm.box)
            server.vm.box_url = settings['boxes'][server.vm.box]
          end
        end
        
        ## Timeouts
        server.vm.boot_timeout = 900

        # Setup SSH and Prevent TTY errors
        server.ssh.username = host['vagrant_user']
        #server.ssh.password = host['vagrant_user_pass']
        server.ssh.private_key_path = host['vagrant_user_private_key_path']
        server.ssh.insert_key = host['vagrant_insert_key']
        server.ssh.forward_agent = true
        #server.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
        #server.ssh.forward_x11 = true


        ## Networking
        ## Note Do not place two IPs in the same subnet on both nics at the same time, They must be different subnets or on a different network segment(ie VLAN, physical seperation for Linux VMs)
        if host.has_key?('networks')
          host['networks'].each_with_index do |network, netindex|
              current_mac = network['mac']
              current_mac = network['mac'].delete! ":" if host['provider-type'] == 'virtualbox'
              server.vm.network "public_network", ip: network['address'], dhcp: network['dhcp4'], dhcp6: network['dhcp6'], bridge: network['bridge'], auto_config: false, :netmask => network['netmask'], :mac => network['mac'], gateway: network['gateway'], nictype: network['type'], nic_number: netindex, managed: network['is_control'], vlan: network['vlan'], use_dhcp_assigned_default_route: true if network['type'] == 'external'
              server.vm.network "private_network", ip: network['address'], dhcp: network['dhcp4'], dhcp6: network['dhcp6'], bridge: network['bridge'], auto_config: false, :netmask => network['netmask'], :mac => network['mac'], gateway: network['gateway'], nictype: network['type'], nic_number: netindex, managed: network['is_control'], vlan: network['vlan'] if network['type'] == 'host'
          end
        end

        # Nameservers -- for Provider: Zones
        if host.has_key?('dns')
          dservers = []
          host['dns'].each do |ns|
            dservers.append(ns['nameserver'])
          end
        end

        ##### Begin Virtualbox Configurations #####        
        server.vm.provider :virtualbox do |vb|	  
          vb.name = "#{host['partition_id']}--#{host['subdomain']}.#{host['domain']}"
          vb.customize ['modifyvm', :id, '--ostype', host['consoleport']]
          vb.customize ["modifyvm", :id, "--vrdeport", host['consoleport']]
          vb.customize ["modifyvm", :id, "--vrdeaddress", host['consolehost']]
          vb.customize ["modifyvm", :id, "--cpus", host['simple_vcpu_conf']]
          vb.customize ["modifyvm", :id, "--memory", host['vbox_memory']]

          if host.has_key?('vbox-port-forwards')
            host['vbox-port-forwards'].each do |param|
              config.vm.network "forwarded_port", guest: param['guest'], host: param['host'], host_ip: param['ip'], use_dhcp_assigned_default_route: true
            end
          end

          if host.has_key?('vbox-directives')
            host['vbox-directives'].each do |param|
              vb.customize ['modifyvm', :id, "--#{param['directive']}", param['value']]
            end
          end
        end
        ##### End Virtualbox Configurations #####

        ##### Begin ZONE type Configurations #####
        server.vm.provider :zone do |vm|
                vm.brand                                = host['brand']
                vm.vagrant_cloud_creator                = host['cloud_creator']
                vm.boxshortname                         = host['boxshortname']
                vm.autoboot                             = host['autostart']
                vm.partition_id                         = host['partition_id']
                vm.setup_wait                           = host['setup_wait']
                vm.zunlockbootkey                       = host['zunlockbootkey']
                vm.zunlockboot                          = host['zunlockboot']
                vm.memory                               = host['memory']
                vm.cpus                                 = host['simple_vcpu_conf']
                vm.cpu_configuration                    = host['cpu_configuration']
                vm.complex_cpu_conf                     = host['complex_cpu_conf']
                vm.console_onboot                       = host['console_onboot']
                vm.consoleport                          = host['consoleport']
                vm.consolehost                          = host['consolehost']
                vm.console                              = host['console']
                vm.dns                                  = host['dns']
                vm.override                             = host['override']
                vm.firmware_type                        = host['firmware_type']
                vm.acpi                                 = host['acpi']
                vm.shared_disk_enabled                  = host['shared_lofs_disk_enabled']
                vm.shared_dir                           = host['shared_lofs_dir']
                vm.os_type                              = host['os_type']
                vm.custom_ci_web_root                   = host['custom_ci_web_root']
                vm.ci_port                              = host['ci_port']
                vm.ci_listen                            = host['ci_listen']
                vm.custom_ci                            = host['custom_ci']
                vm.allowed_address                      = host['allowed_address']
                vm.diskif                               = host['diskif']
                vm.netif                                = host['netif']
                vm.hostbridge                           = host['hostbridge']
                vm.clean_shutdown_time                  = host['clean_shutdown_time']
                vm.vmtype                               = host['vmtype']
                vm.vagrant_user_private_key_path        = host['vagrant_user_private_key_path']
                vm.vagrant_user                         = host['vagrant_user']
                vm.vagrant_user_pass                    = host['vagrant_user_pass']
                vm.hostname                             = "#{host['subdomain']}.#{host['domain']}"
                vm.name                                 = "#{host['partition_id']}--#{host['subdomain']}.#{host['domain']}"
                vm.booted_string                        = host['booted_string']
                vm.lcheck                               = host['lcheck_string']
                vm.alcheck                              = host['alcheck_string']
                vm.debug_boot                           = host['debug_boot']
                vm.debug                                = host['debug']
                vm.cdroms                               = host['cdroms']
                vm.additional_disks                     = host['additional_disks']
                vm.boot                                 = host['boot']
                vm.snapshot_script                      = host['snapshot_script']
                vm.cloud_init_enabled                   = host['cloud_init_enabled']
                vm.cloud_init_dnsdomain                 = host['cloud_init_dnsdomain']
                vm.cloud_init_password                  = host['vagrant_user_pass']
                vm.cloud_init_resolvers                 = dservers.join(',')
                vm.cloud_init_sshkey                    = host['vagrant_user_private_key_path']
                vm.cloud_init_conf                      = host['cloud_init_conf']
                vm.safe_restart                         = host['safe_restart']
                vm.safe_shutdown                        = host['safe_shutdown']
                vm.setup_method                         = host['setup_method']            
        end
        ## End Vagrant-Zones Configurations 

        # Register shared folders
        if host.has_key?('folders')
					host['folders'].each do |folder|
						mount_opts = folder['type'] == folder['type'] ? ['actimeo=1'] : [] 
						server.vm.synced_folder folder['map'], folder ['to'],
						type: folder['type'],
						owner: folder['owner'] ||= host['vagrant_user'],
						group: folder['group'] ||= host['vagrant_user'],
						mount_options: mount_opts,
						automount: true,
            rsync__args: folder['rsync__args'] ||= ["--verbose", "--archive", "--delete", "-z", "--copy-links"],
						rsync__chown:  folder['rsync__chown'] ||= 'false',
						rsync__rsync_ownership:  folder['rsync__rsync_ownership'] ||= 'true',
						disabled: folder['disabled']||= false
					end
				end

        # Add Branch Files to Vagrant Share on VM Change to Git folders to pull
        scriptsPath = File.dirname(__FILE__) + '/branches'
        if host.has_key?('branch') && host['shell_provision']
            server.vm.provision 'shell' do |s|
              s.path = scriptsPath + '/add-branch.sh'
              s.args = [host['branch'], host['git_url'] ]
            end
        end

        # Run the shell provisioners defined in hosts.yml
        if host.has_key?('provision_scripts') && host['shell_provision']
          host['provision_scripts'].each do |file|
              server.vm.provision 'shell', path: file
          end
        end

        # Run the Ansible Provisioners -- You can pass Host.yaml variables to Ansible via the Extra_vars variable as noted below.
        if host.has_key?('ansible_provision_scripts') && host['ansible_provision']
          host['ansible_provision_scripts'].each do |scripts|

            ## If Ansible is not available on the host and is installed in the template you are spinning up, use 'ansible-local'
            if scripts.has_key?('local')
              scripts['local'].each do |localscript|
                server.vm.provision :ansible_local do |ansible|
                  ansible.playbook = localscript['script']
                  ansible.compatibility_mode = localscript['compatibility_mode'].to_s
                  ansible.install_mode = "pip" if localscript['install_mode'] == "pip"
                  ansible.extra_vars = {subdomain: "#{host['subdomain']}", domain: "#{host['domain']}", dns: dservers, networks: host['networks'], secrets:secrets, rv:host['rolevars'], ansible_python_interpreter:localscript['ansible_python_interpreter']}
                end
              end
            end

            ## If Ansible is available on the host or is not installed in the template you are spinning up, use 'ansible'
            if scripts.has_key?('remote')
              scripts['remote'].each do |remotescript|
                server.vm.provision :ansible do |ansible|
                  ansible.playbook = remotescript['script']
                  ansible.compatibility_mode = remotescript['compatibility_mode'].to_s
                  ansible.extra_vars = {subdomain: "#{host['subdomain']}", domain: "#{host['domain']}", dns: dservers, networks: host['networks'], secrets:secrets, rv:host['rolevars'], ansible_python_interpreter:remotescript['ansible_python_interpreter']}
                end
              end
            end
          end
        end
      end
      
      ## Open the browser after provisioning
      if host['open-browser'] && host.has_key?('networks') && host['provider-type'] == 'virtualbox'
        host['networks'].each_with_index do |network, netindex|  
          config.trigger.after [:up] do |trigger|
            trigger.ruby do |env,machine|
              if network['dhcp4']
                system("vagrant ssh -c 'cat /ipaddress.yml' > detectedpublicaddress.txt")
                ipaddress = File.readlines("detectedpublicaddress.txt").join("")
                open_url = "https://" + ipaddress + ":443/downloads/welcome.html"
              else
                ipaddress = network['address']
                open_url = "https://" + ipaddress + ":443/downloads/welcome.html"
              end
              system("/bin/bash -c 'xdg-open #{ open_url}'") if Vagrant::Util::Platform.linux?
              system("open", "#{ open_url}") if Vagrant::Util::Platform.windows?  
              system("open", "#{ open_url}") if Vagrant::Util::Platform.darwin?
            end
          end
        end
      end
    end
  end
end

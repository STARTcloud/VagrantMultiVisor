## Vagrant File tooling compatabile with Bhyve and Virtualbox, potentially ESXI/Vmware,KVM
require 'yaml'

## Instead of lumping the code with the variables that need to be modified, let's seperate these out into YAML.
## If in seperate blocks, theoretically multiple machines can be configured in the same file
configuration = YAML::load(File.read("#{File.dirname(__FILE__)}/Hosts.yml"))
runPath = "#{File.dirname(__FILE__)}/" + configuration["path"]

## This takes the above configuration file and set's the appropriate Vagrant/Hypervisor settings
require File.expand_path("#{runPath}/Hosts.rb")

# This is the function that runs Vagrant through Hosts.rb to pass the variables to Vagrant
Vagrant.configure("2") do |config|
        Hosts.configure(config, configuration)
end

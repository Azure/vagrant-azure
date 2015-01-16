#---------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#---------------------------------------------------------------------------

module VagrantPlugins
  module WinAzure
    module Action
      class Provision < Vagrant::Action::Builtin::Provision
        # Override the core vagrant method and branch out for windows
        def run_provisioner(env)
          env[:machine].id =~ /@/
          vm = env[:azure_vm_service].get_virtual_machine($`, $')
          env[:ui].info "VM OS: #{vm.os_type.to_sym}"

          if vm.os_type.to_sym == :Windows
            env[:ui].info 'Provisioning for Windows'

            case env[:provisioner].class.to_s
              when 'VagrantPlugins::Shell::Provisioner'
                env[:provisioner].provision
              when 'VagrantPlugins::Puppet::Provisioner::Puppet'
                VagrantPlugins::WinAzure::Provisioner::Puppet.new(
                    env
                ).provision_for_windows
              when 'VagrantPlugins::Chef::Provisioner::ChefSolo'
                VagrantPlugins::WinAzure::Provisioner::ChefSolo.new(
                    env
                ).provision_for_windows
              else
                env[:provisioner].provision
            end
          else
            env[:ui].info 'Provisioning using SSH'
            env[:provisioner].provision
          end
        end
      end
    end
  end
end

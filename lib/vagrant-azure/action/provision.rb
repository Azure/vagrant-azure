#---------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
#--------------------------------------------------------------------------

# Overriding the core vagrant class because of the lack of non-ssh based
# communication infrastructure.
# This will be moved to an 'rdp' communicator when the core supports it.

module VagrantPlugins
  module WinAzure
    module Action
      class Provision < Vagrant::Action::Builtin::Provision
        # Override the core vagrant method and branch out for windows
        def run_provisioner(env)
          env[:ui].info "Provisioner: #{env[:provisioner].class.to_s}"

          env[:machine].id =~ /@/
          vm = env[:azure_vm_service].get_virtual_machine($`, $')
          env[:ui].info "VM OS: #{vm.os_type.to_s}"

          if vm.os_type.to_s == :Windows
            # Raise an error if we're not on a Windows Host.
            # Non-Windows OS will be supported once we move to WinRb/WinRm
            raise 'Unsupported OS for Windows Provisioning' unless \
              Vagrant::Util::Platform.windows?
            env[:ui].info "Provisioning for Windows"
          else
            env[:ui].info "Provisioning using SSH"
            env[:provisioner].provision
          end
        end
      end
    end
  end
end

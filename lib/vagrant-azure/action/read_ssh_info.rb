#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------
require 'log4r'

module VagrantPlugins
  module WinAzure
    module Action
      class ReadSSHInfo
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure::action::read_ssh_info')
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(
            env[:azure_vm_service],
            env[:machine]
          )

          @app.call(env)
        end

        def read_ssh_info(azure, machine)
          return nil if machine.id.nil?
          machine.id =~ /@/
          vm = azure.get_virtual_machine($`, $')

          if vm.nil? || !vm.instance_of?(Azure::VirtualMachineManagement::VirtualMachine)
            # Machine cannot be found
            @logger.info 'Machine not found. Assuming it was destroyed'
            machine.id = nil
            return nil
          end

          vm.tcp_endpoints.each do |endpoint|
            l_port = endpoint['LocalPort']
            if l_port == '22'
              return { :host => endpoint['Vip'], :port => endpoint['PublicPort'] }
            end
          end

          return nil
        end
      end
    end
  end
end

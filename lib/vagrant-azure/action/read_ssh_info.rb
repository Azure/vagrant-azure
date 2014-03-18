#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
#--------------------------------------------------------------------------
require 'log4r'

module VagrantPlugins
  module WinAzure
    module Action
      class ReadSSHInfo
        def initialize(app, env, port = 22)
          @app = app
          @port = port
          @logger = Log4r::Logger.new('vagrant_azure::action::read_ssh_info')
        end

        def call(env)
          env[:ui].info "Looking for #{@port}"

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
            l_port = endpoint[:local_port]
            if l_port == "#{@port}"
              return { :host => endpoint[:vip], :port => endpoint[:public_port] }
            end
          end

          return nil
        end
      end
    end
  end
end

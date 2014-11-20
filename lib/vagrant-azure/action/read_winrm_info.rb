#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#--------------------------------------------------------------------------
require 'log4r'

module VagrantPlugins
  module WinAzure
    module Action
      class ReadWinrmInfo
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure::action::read_winrm_info')
        end

        def call(env)
          if env[:machine].config.vm.guest == :windows
            env[:ui].info 'Looking for WinRM'

            env[:machine_winrm_info] = read_winrm_info(
              env[:azure_vm_service],
              env[:machine]
            )
          end

          @app.call(env)
        end

        def read_winrm_info(azure, machine)
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
            if endpoint[:name] == 'PowerShell'
              machine.config.winrm.host = "#{vm.cloud_service_name}.cloudapp.net"
              machine.config.winrm.port = endpoint[:public_port]
              return { :host => "#{vm.cloud_service_name}.cloudapp.net", :port => endpoint[:public_port] }
            end
          end

          nil
        end
      end
    end
  end
end

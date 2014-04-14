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
          vm = nil
          attempt = 0
          while true
            begin
              vm = azure.get_virtual_machine($`, $')
            rescue SocketError
              attempt = attempt + 1
              env[:ui].info(I18n.t("vagrant_azure.read_attempt",
                                  :attempt => attempt))
              sleep 5
              next if attempt < 3
            end
            break
          end

          if vm.nil? || !vm.instance_of?(Azure::VirtualMachineManagement::VirtualMachine)
            # Machine cannot be found
            @logger.info 'Machine not found. Assuming it was destroyed'
            machine.id = nil
            return nil
          end

          vm.tcp_endpoints.each do |endpoint|
            if endpoint[:local_port] == "#{@port}"
              return { :host => "#{vm.cloud_service_name}.cloudapp.net", :port => endpoint[:public_port] }
            end
          end

          return nil
        end
      end
    end
  end
end

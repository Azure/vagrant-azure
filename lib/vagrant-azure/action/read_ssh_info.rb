# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.
require 'log4r'

module VagrantPlugins
  module Azure
    module Action
      class ReadSSHInfo
        def initialize(app, env, port = 22)
          @app = app
          @port = port
          @logger = Log4r::Logger.new('vagrant_azure::action::read_ssh_info')
        end

        def call(env)
          env[:ui].detail "Looking for local port #{@port}"

          env[:machine_ssh_info] = read_ssh_info(
            env[:azure_vm_service],
            env[:machine]
          )

          env[:ui].detail "Found port mapping #{env[:machine_ssh_info][:port]} --> #{@port}"

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

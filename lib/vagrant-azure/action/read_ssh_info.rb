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
            env[:azure_arm_service],
            env
          )

          env[:ui].detail "Found port mapping #{env[:machine_ssh_info][:port]} --> #{@port}"

          @app.call(env)
        end

        def read_ssh_info(azure, env)
          return nil if env[:machine].id.nil?
          resource_group_name, vm_name = env[:machine].id.split(':')
          vm = azure.compute.virtual_machines.get(resource_group_name, vm_name, 'instanceView').value!.body

          if vm.nil?
            # Machine cannot be found
            @logger.info 'Machine not found. Assuming it was destroyed and cleaning up environment'
            terminate(env)
            return nil
          end

          # vm.tcp_endpoints.each do |endpoint|
          #   if endpoint[:local_port] == "#{@port}"
          #     return { :host => "#{vm.cloud_service_name}.cloudapp.net", :port => endpoint[:public_port] }
          #   end
          # end

          return nil
        end

        def terminate(env)
          destroy_env = env.dup
          destroy_env.delete(:interrupted)
          destroy_env[:config_validate] = false
          destroy_env[:force_confirm_destroy] = true
          env[:action_runner].run(Action.action_destroy, destroy_env)
        end
      end
    end
  end
end

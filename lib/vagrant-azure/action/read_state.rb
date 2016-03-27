# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.
require 'log4r'

module VagrantPlugins
  module Azure
    module Action
      class ReadState
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure::action::read_state')
        end

        def call(env)
          env[:machine_state_id] = read_state(env[:azure_arm_service], env)
          @app.call(env)
        end

        def read_state(azure, env)
          machine = env[:machine]
          return :not_created if machine.id.nil?

          # Find the machine
          rg_name, vm_name = machine.id.split(':')
          vm = nil
          begin
            vm = azure.compute.virtual_machines.get(rg_name, vm_name, 'instanceView').value!.body
          rescue MsRestAzure::AzureOperationError => ex
            if vm.nil? || [:'shutting-down', :terminated].include?(vm.state.to_sym)
              # The machine can't be found
              @logger.info('Machine not found or terminated, assuming it got destroyed.')
              machine.id = nil
              return :not_created
            end
          end

          # Return the state
          vm.state.to_sym
        end

      end
    end
  end
end

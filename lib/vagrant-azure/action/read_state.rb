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
          env[:machine_state_id] = read_state(env[:azure_arm_service], env[:machine])

          @app.call(env)
        end

        # def read_state(azure, machine)
        #   env[:machine].id = "#{env[:machine].provider_config.vm_name}@#{env[:machine].provider_config.cloud_service_name}" unless env[:machine].id
        #
        #   env[:machine].id =~ /@/
        #
        #   env[:ui].info "Attempting to read state for #{$`} in #{$'}"
        #
        #   vm = env[:azure_vm_service].get_virtual_machine($`, $')
        #
        #   if vm.nil? || \
        #     !vm.instance_of?(Azure::VirtualMachineManagement::VirtualMachine) || \
        #     [ :DeletingVM ].include?(vm.status.to_sym)
        #     # Machine can't be found
        #     @logger.info 'Machine cannot be found'
        #     env[:machine].id = nil
        #     return :NotCreated
        #   end
        #
        #   env[:ui].info "VM Status: #{vm.status.to_sym}"
        #   return vm.status.to_sym
        # end

        def read_state(azure, machine)
          return :not_created if machine.id.nil?

          # Find the machine
          config = machine.provider_config
            server = azure.compute.virtual_machines.get(config.resource_group_name, machine.name, true).value!
          if server.nil? || [:'shutting-down', :terminated].include?(server.state.to_sym)
            # The machine can't be found
            @logger.info('Machine not found or terminated, assuming it got destroyed.')
            machine.id = nil
            return :not_created
          end

          # Return the state
          server.state.to_sym
        end
      end
    end
  end
end

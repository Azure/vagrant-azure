# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.
require 'log4r'
require 'vagrant-azure/util/vm_status_translator'
require 'vagrant-azure/util/machine_id_helper'

module VagrantPlugins
  module Azure
    module Action
      class ReadState
        include VagrantPlugins::Azure::Util::VMStatusTranslator
        include VagrantPlugins::Azure::Util::MachineIdHelper

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure::action::read_state')
        end

        def call(env)
          env[:machine_state_id] = read_state(env[:azure_arm_service], env[:machine])
          @app.call(env)
        end

        def read_state(azure, machine)
          return :not_created if machine.id.nil?

          # Find the machine
          parsed = parse_machine_id(machine.id)
          vm = nil
          begin
            vm = azure.compute.virtual_machines.get(parsed[:group], parsed[:name], 'instanceView')
          rescue MsRestAzure::AzureOperationError => ex
            if vm.nil? || tearing_down?(vm.instance_view.statuses)
              # The machine can't be found
              @logger.info('Machine not found or terminated, assuming it got destroyed.')
              machine.id = nil
              return :not_created
            end
          end

          # Return the state
          power_state(vm.instance_view.statuses)
        end

      end
    end
  end
end

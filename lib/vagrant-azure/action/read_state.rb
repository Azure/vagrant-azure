#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------
require 'log4r'

module VagrantPlugins
  module WinAzure
    module Action
      class ReadState
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure::action::read_state')
        end

        def call(env)
          env[:machine_state_id] = read_state(env)

          @app.call(env)
        end

        def read_state(env)
          return :NotCreated if env[:machine].id.nil?

          env[:machine].id =~ /@/

          env[:ui].info "Attempting to read state for #{$`} in #{$'}"

          vm = env[:azure_vm_service].get_virtual_machine($`, $')

          env[:ui].info "VM Status: #{vm.status.to_sym}"

          if vm.nil?
            @logger.info 'Machine cannot be found'
            env[:machine].id = nil
            return :NotCreated
          end

          return vm.status.to_sym
        end
      end
    end
  end
end

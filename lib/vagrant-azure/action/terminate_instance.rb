# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.
require 'log4r'

module VagrantPlugins
  module Azure
    module Action
      class TerminateInstance
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure::action::terminate_instance')
        end

        def call(env)
          env[:machine].id =~ /@/

          vm = env[:azure_vm_service].get_virtual_machine($`, $')

          if vm.nil?
            # machine not found. assuming it was not created or destroyed
            env[:ui].info (I18n.t('vagrant_azure.not_created'))
          else
            env[:azure_vm_service].delete_virtual_machine($`, $')
            env[:machine].id = nil
          end

          @app.call(env)
        end
      end
    end
  end
end

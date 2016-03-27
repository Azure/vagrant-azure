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
          rg_name, vm_name = env[:machine].id.split(':')

          env[:azure_arm_service].compute.virtual_machines.delete(rg_name, vm_name).value!.body
          env[:machine].id = nil

          @app.call(env)
        end
      end
    end
  end
end

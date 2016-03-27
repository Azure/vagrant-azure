# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.
require 'log4r'

module VagrantPlugins
  module Azure
    module Action
      class RestartVM
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure::action::restart_vm')
        end

        def call(env)
          env[:machine].id =~ /@/

          env[:ui].info "Restarting #{$`} in #{$'}"
          env[:azure_vm_service].restart_virtual_machine($`, $')

          @app.call(env)
        end
      end
    end
  end
end

#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#--------------------------------------------------------------------------
require 'log4r'

module VagrantPlugins
  module WinAzure
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

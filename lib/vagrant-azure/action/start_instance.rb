#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#--------------------------------------------------------------------------
require 'log4r'

# require 'vagrant/util/retryable'

# Barebones basic implemenation. This a work in progress in very early stages
module VagrantPlugins
  module WinAzure
    module Action
      # This starts a stopped instance
      class StartInstance
        # include Vagrant:Util::Retryable

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure:action::start_instance')
        end

        def call(env)
          env[:machine].id = "#{env[:machine].provider_config.vm_name}@#{env[:machine].provider_config.cloud_service_name}" unless env[:machine].id
          env[:machine].id =~ /@/

          env[:ui].info "Attempting to start '#{$`}' in '#{$'}'"

          env[:azure_vm_service].start_virtual_machine($`, $')

          @app.call(env)
        end
      end
    end
  end
end

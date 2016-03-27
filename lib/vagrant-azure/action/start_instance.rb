# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.
require 'log4r'

# require 'vagrant/util/retryable'

# Bare bones basic implementation. This a work in progress in very early stages
module VagrantPlugins
  module Azure
    module Action
      # This starts a stopped instance
      class StartInstance

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure:action::start_instance')
        end

        def call(env)
          env[:machine].id = "#{env[:machine].provider_config.vm_name}@#{env[:machine].provider_config.cloud_service_name}" unless env[:machine].id
          env[:machine].id =~ /@/

          VagrantPlugins::Azure::CLOUD_SERVICE_SEMAPHORE.synchronize do
            env[:ui].info "Attempting to start '#{$`}' in '#{$'}'"
            env[:azure_vm_service].start_virtual_machine($`, $')
          end
          @app.call(env)
        end
      end
    end
  end
end

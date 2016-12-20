# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.
require_relative '../services/azure_resource_manager'
require 'log4r'

module VagrantPlugins
  module Azure
    module Action
      class ConnectAzure
        def initialize(app, _)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure::action::connect_azure')
        end

        def call (env)
          if env[:azure_arm_service].nil?
            config = env[:machine].provider_config
            provider = MsRestAzure::ApplicationTokenProvider.new(config.tenant_id, config.client_id, config.client_secret)
            env[:azure_arm_service] = VagrantPlugins::Azure::Services::AzureResourceManager.new(provider, config.subscription_id)
          end

          @app.call(env)
        end
      end
    end
  end
end

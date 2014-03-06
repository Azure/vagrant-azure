#---------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------
require 'azure'
require 'log4r'

module VagrantPlugins
  module WinAzure
    module Action
      class ConnectAzure
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure::action::connect_aws')
        end

        def call (env)
          config = env[:machine].provider_config

          env[:ui].warn "Subscription ID: [#{config.subscription_id}]"
          env[:ui].warn "Mangement Certificate: [#{config.mgmt_certificate}]"
          env[:ui].warn "Mangement Endpoint: [#{config.mgmt_endpoint}]"
          env[:ui].warn "Storage Account Name: [#{config.storage_acct_name}]"
          env[:ui].warn "Storage Access Key: [#{config.storage_access_key}]"

          Azure.configure do |c|
            c.subscription_id                       = config.subscription_id
            c.management_certificate                = config.mgmt_certificate
            c.management_endpoint                   = config.mgmt_endpoint
            c.storage_account_name                  = config.storage_acct_name
            c.storage_access_key                    = config.storage_access_key
          end

          env[:azure_vm_service] = Azure::VirtualMachineManagementService.new

          @app.call(env)
        end
      end
    end
  end
end

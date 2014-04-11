#---------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
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

          env[:ui].info "Subscription ID: [#{config.subscription_id}]"
          env[:ui].info "Mangement Certificate: [#{config.mgmt_certificate}]"
          env[:ui].info "Mangement Endpoint: [#{config.mgmt_endpoint}]"
          env[:ui].info "Storage Account Name: [#{config.storage_acct_name}]"

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

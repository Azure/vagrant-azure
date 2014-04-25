#---------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
#--------------------------------------------------------------------------
require 'azure'
require 'log4r'

# FIXME:
# This is a required to patch few exception handling which are not done in
# Azure Ruby SDK
require_relative "vagrant_azure_service"

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

          Azure.configure do |c|
            c.subscription_id                       = config.subscription_id
            c.management_certificate                = config.mgmt_certificate
            c.management_endpoint                   = config.mgmt_endpoint
            c.storage_account_name                  = config.storage_acct_name
            c.storage_access_key                    = config.storage_access_key
          end

          # FIXME:
          # Defining a new class VagrantAzureService
          # Here we call the native azure virtual machine management service method
          # and add some exception handling.
          # Remove this once the Azure SDK adds the exception handling for the
          # methods defined in VagrantAzureService
          env[:azure_vm_service] = VagrantAzureService.new(Azure::VirtualMachineManagementService.new, env)

          @app.call(env)
        end
      end
    end
  end
end

# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.

module VagrantPlugins
  module Azure
    module Errors
      class AzureError < Vagrant::Errors::VagrantError
        error_namespace('vagrant_azure.errors')
      end

      class WinRMNotReady < AzureError
        error_key(:win_rm_not_ready)
      end

      class ServerNotCreated < AzureError
        error_key(:server_not_created)
      end

      class CreateVMFailure < AzureError
        error_key(:create_vm_failure)
      end

    end
  end
end

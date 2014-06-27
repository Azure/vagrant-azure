#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#--------------------------------------------------------------------------

module VagrantPlugins
  module WinAzure
    module Errors
      class WinAzureError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_azure.errors")
      end

      class WinRMNotReady < WinAzureError
        error_key(:win_rm_not_ready)
      end

      class ServerNotCreated < WinAzureError
        error_key(:server_not_created)
      end

      class CreateVMFailure < WinAzureError
        error_key(:create_vm_failure)
      end

    end
  end
end

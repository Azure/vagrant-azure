#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
#--------------------------------------------------------------------------
module VagrantPlugins
  module WinAzure
    module Errors
      class VagrantAzureError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_azure.errors")
      end

      class CreateVMFailure < VagrantAzureError
        error_key(:create_vm_failure)
      end

      class CreateVMError < VagrantAzureError
        error_key(:create_vm_error)
      end
    end
  end
end

#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
#--------------------------------------------------------------------------

module VagrantPlugins
  module WinAzure
    module Communicator
      class PowerShell < Vagrant.plugin("2", :communicator)
        def initialize(machine)
          @machine = machine
        end

        def wait_for_ready(timeout)
          ready?
        end

        def ready?
          # Return True when the guest has enabled WinRM
          # In this case we can try any remote PowerShell commands to see if
          # further vagrant can be carried out using this communication
          if !@winrm_status
            status = false
            response = @machine.provider.driver.check_winrm
            message = nil
            if response && response["message"]
              message = response["message"]
              @winrm_status = message == "Running"
            end
            raise Errors::WinRMNotReady, message: message if !@winrm_status
          end
          @winrm_status
        end

        def test(command, opts=nil)
          true
        end
      end
    end
  end
end

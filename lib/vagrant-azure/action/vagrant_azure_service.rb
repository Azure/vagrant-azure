#---------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
#--------------------------------------------------------------------------
# FIXME:
# This is a stop gap arrangement until the azure ruby SDK fixes the exceptions
# and gracefully fails.

module VagrantPlugins
  module WinAzure
    module Action
      class VagrantAzureService
        attr_reader :azure
        def initialize(azure)
          @azure = azure
        end

        # At times due to network latency the SDK raises SocketError, this can
        # be rescued and re-try for three attempts.
        def get_virtual_machine(*args)
          vm = nil
          attempt = 0
          while true
            begin
              vm = azure.get_virtual_machine(*args)
            rescue SocketError
              attempt = attempt + 1
              sleep 5
              next if attempt < 3
            end
            break
          end
          vm
        end

        def method_missing(method, *args, &block)
          azure.send(method, *args, &block)
        end

      end
    end
  end
end

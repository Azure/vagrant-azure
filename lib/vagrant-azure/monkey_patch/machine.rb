#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
#--------------------------------------------------------------------------

module Vagrant
  class Machine

    ssh_communicate = instance_method(:communicate)

    define_method(:communicate) do
      unless @communicator
        if @config.vm.guest == :windows
          @communicator = VagrantPlugins::WinAzure::Communicator::PowerShell.new(self)
        else
         @communicator = original_communicate
        end
      end
      @communicator
    end
  end
end

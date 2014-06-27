#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#--------------------------------------------------------------------------

module Vagrant
  class Machine

    ssh_communicate = instance_method(:communicate)

    define_method(:communicate) do
      unless @communicator
        if @config.vm.guest == :windows
          @communicator = VagrantPlugins::WinAzure::Communicator::PowerShell.new(self)
        else
         @communicator = ssh_communicate.bind(self).()
        end
      end
      @communicator
    end
  end
end

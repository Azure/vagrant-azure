#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------
module VagrantPlugins
  module WinAzure
    class Command < Vagrant.plugin('2', :command)
      def self.synopsis
        'Opens an RDP session for a vagrant machine'
      end

      def execute
        with_target_vms do |vm|
          vm.action(:rdp)
        end

        0
      end
    end
  end
end

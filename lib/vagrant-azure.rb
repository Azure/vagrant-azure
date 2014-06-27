#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#--------------------------------------------------------------------------
require 'pathname'
require 'vagrant-azure/plugin'

module VagrantPlugins
  module WinAzure
    lib_path = Pathname.new(File.expand_path('../vagrant-azure', __FILE__))
    autoload :Action, lib_path.join('action')
    autoload :Errors, lib_path.join('errors')
    autoload :Driver, lib_path.join('driver')

    # Load a communicator for Windows guest
    require lib_path.join("communication/powershell")

    require lib_path.join('provisioner/puppet')
    require lib_path.join('provisioner/chef-solo')
    require lib_path.join('provisioner/shell')

    monkey_patch = Pathname.new(File.expand_path("../vagrant-azure/monkey_patch", __FILE__))
    # Monkey Patch the core Hyper-V vagrant with the following
    require monkey_patch.join("machine")

    # This returns the path to the source of this plugin.
    #
    # @return [Pathname]
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end
  end
end

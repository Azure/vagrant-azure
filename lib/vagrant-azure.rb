#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
#--------------------------------------------------------------------------
require 'pathname'
require 'vagrant-azure/plugin'

module VagrantPlugins
  module WinAzure
    lib_path = Pathname.new(File.expand_path('../vagrant-azure', __FILE__))
    autoload :Action, lib_path.join('action')
    autoload :Error, lib_path.join('errors')
    autoload :Driver, lib_path.join('driver')

    require lib_path.join('provisioner/puppet')
    require lib_path.join('provisioner/chef-solo')

    # This returns the path to the source of this plugin.
    #
    # @return [Pathname]
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end
  end
end

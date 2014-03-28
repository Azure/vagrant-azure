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

    monkey_patch = Pathname.new(File.expand_path("../vagrant-azure/monkey_patch", __FILE__))
    require monkey_patch.join("util/powershell")

    # This returns the path to the source of this plugin.
    #
    # @return [Pathname]
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end
  end
end

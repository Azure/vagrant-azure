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

    Vagrant.plugin('2').manager.communicators[:winrm]
    require 'kconv'
    require lib_path.join('monkey_patch/azure')
    require lib_path.join('monkey_patch/winrm')

    CLOUD_SERVICE_SEMAPHORE = Mutex.new


    # This returns the path to the source of this plugin.
    #
    # @return [Pathname]
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end
  end
end

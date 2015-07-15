#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#--------------------------------------------------------------------------
begin
  require 'vagrant'
rescue LoadError
  raise 'The Vagrant Azure plugin must be run within Vagrant.'
end

# This is a sanity check to make sure no one is attempting to install this into
# an early Vagrant version.
if Vagrant::VERSION < '1.6.0'
  raise 'The Vagrant Azure plugin is only compatible with Vagrant 1.6+'
end

module VagrantPlugins
  module WinAzure
    class Plugin < Vagrant.plugin('2')
      name 'azure'
      description <<-DESC
      This plugin installs a provider that allows Vagrant to manage
      machines in Windows Azure.
      DESC

      config(:azure, :provider) do
        require_relative 'config'
        Config
      end

      provider(:azure, parallel: true) do
        # Setup logging and i18n
        setup_logging
        setup_i18n
        apply_patches

        # Return the provider
        require_relative 'provider'
        Provider
      end

      provider_capability(:azure, :winrm_info) do
        require_relative 'capabilities/winrm'
        VagrantPlugins::WinAzure::Cap::WinRM
      end

      command 'powershell' do
        require_relative 'command/powershell'
        VagrantPlugins::WinAzure::Command::PowerShell
      end

      command 'rdp' do
        require_relative 'command/rdp'
        VagrantPlugins::WinAzure::Command::RDP
      end

      def self.apply_patches
        lib_path = Pathname.new(File.expand_path('../../vagrant-azure', __FILE__))
        Vagrant.plugin('2').manager.communicators[:winrm]
        require lib_path.join('monkey_patch/winrm')
      end

      def self.setup_i18n
        I18n.load_path << File.expand_path(
          'locales/en.yml',
          WinAzure.source_root
        )
        I18n.load_path << File.expand_path(
          'templates/locales/en.yml',
          Vagrant.source_root
        )
        I18n.load_path << File.expand_path(
          'templates/locales/providers_hyperv.yml',
          Vagrant.source_root
        )
        I18n.reload!
      end

      def self.setup_logging
        require 'log4r'

        level = nil
        begin
          level = Log4r.const_get(ENV['VAGRANT_LOG'].upcase)
        rescue NameError
          # This means that the logging constant wasn't found,
          # which is fine. We just keep `level` as `nil`. But
          # we tell the user.
          level = nil
        end

        # Some constants, such as "true" resolve to booleans, so the
        # above error checking doesn't catch it. This will check to make
        # sure that the log level is an integer, as Log4r requires.
        level = nil if !level.is_a?(Integer)

        # Set the logging level on all "vagrant" namespaced logs as long as
        # we have a valid level
        if level
          logger = Log4r::Logger.new("vagrant_azure")
          logger.outputters = Log4r::Outputter.stderr
          logger.level = level
          logger = nil
        end
      end
    end
  end
end

#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
#--------------------------------------------------------------------------
begin
  require 'vagrant'
rescue LoadError
  raise 'The Vagrant Azure plugin must be run within Vagrant.'
end

# This is a sanity check to make sure no one is attempting to install this into
# an early Vagrant version.
if Vagrant::VERSION < '1.2.0'
  raise 'The Vagrant Azure plugin is only compatible with Vagrant 1.2+'
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

        # Return the provider
        require_relative 'provider'
        Provider
      end

      command 'rdp' do
        require_relative 'command/rdp/command'
        Command
      end

      def self.setup_i18n
        I18n.load_path << File.expand_path(
          'locales/en.yml',
          WinAzure.source_root
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

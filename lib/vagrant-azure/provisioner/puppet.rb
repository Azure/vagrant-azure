#---------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
#---------------------------------------------------------------------------
require 'fileutils'
require 'tempfile'

module VagrantPlugins
  module WinAzure
    module Provisioner
      class Puppet
        attr_reader :provisioner

        def initialize(env)
          @env = env
          @provisioner = env[:provisioner]
        end

        def provision_for_windows
          options = [config.options].flatten
          @module_paths = provisioner.instance_variable_get('@module_paths')
          @hiera_config_path = provisioner.instance_variable_get(
            '@hiera_config_path'
          )
          @manifest_file = provisioner.instance_variable_get('@manifest_file')

          # Copy the manifests directory to the guest
          if config.manifests_path[0].to_sym == :host
            @env[:machine].provider.driver.upload(
              File.expand_path(
                config.manifests_path[1], @env[:machine].env.root_path
              ),
              provisioner.manifests_guest_path
            )
          end

          # Copy the module paths to the guest
          @module_paths.each do |from, to|
            @env[:machine].provider.driver.upload(from.to_s, to)
          end

          module_paths = @module_paths.map { |_, to| to }
          unless module_paths.empty?
            win_paths = []
            # Prepend the default module path
            module_paths.unshift('/ProgramData/PuppetLabs/puppet/etc/modules')
            module_paths.each do |path|
              path = path.gsub('/', '\\')
              path = "C:#{path}" if path =~/^\\/
              win_paths << path
            end

            # Add the command  line switch to add the module path
            options << "--modulepath \"#{win_paths.join(';')}\""
          end

          if @hiera_config_path
            options << "--hiera_config=#{@hiera_config_path}"

            # Upload Hiera configuration if we have it
            local_hiera_path = File.expand_path(
              config.hiera_config_path,
              @env[:machine].env.root_path
            )

            @env[:machine].provider.driver.upload(
              local_hiera_path,
              @hiera_config_path
            )
          end

          options << "--manifestdir #{provisioner.manifests_guest_path}"
          options << "--detailed-exitcodes"
          options << @manifest_file
          options  = options.join(' ')

          # Build up the custome facts if we have any
          facter = ''
          unless config.facter.empty?
            facts = []
            config.facter.each do |key, value|
              facts << "FACTER_#{key}='#{value}'"
            end

            facter = "#{facts.join(' ')}"
          end

          command = "#{facter}puppet apply #{options}"

          if config.working_directory
            command = "cd #{config.working_directory} && #{command}"
          end

          @env[:ui].info I18n.t(
            'vagrant_azure.provisioners.puppet.running_puppet',
            manifest: config.manifest_file
          )
          @env[:ui].info 'Executing puppet script in Windows Azure VM'
          @env[:machine].provider.driver.run_remote_ps(command) do |type, data|
            # Output the data with the proper color based on the stream.
            if (type == :stdout || type == :stderr)
              @env[:ui].detail data
            end
          end
        end

        protected

        def config
          provisioner.config
        end
      end
    end
  end
end

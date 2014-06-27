#---------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#---------------------------------------------------------------------------
module VagrantPlugins
  module WinAzure
    module Provisioner
      class Shell
        attr_reader :provisioner

        def initialize(env)
          @env = env
          @provisioner = env[:provisioner]
        end

        def provision_for_windows
          arguments = ''
          arguments = "#{config.args}" if config.args

          with_windows_script_file do |path|
            guest_path = if File.extname(config.upload_path) == ''
              "#{config.upload_path}#{File.extname(path.to_s)}"
            else
              config.upload_path
            end

            @env[:ui].detail "Uploading [#{path}] to [#{guest_path}]"

            response = @env[:machine].provider.driver.upload(path, guest_path)

            command = "powershell.exe #{guest_path} #{arguments}"
            @env[:machine].provider.driver.run_remote_ps(
              command
            ) do |type, data|
              if type == :stdout || type == :stderr
                @env[:ui].detail data
              end
            end
          end
        end

        protected

        def config
          provisioner.config
        end

        def with_windows_script_file
          if config.remote?
            download_path = @env[:machine].env.tmp_path.join(
              "#{env[:mahine].id}-remote-script#{File.extname(config.path)}"
            )

            download_path.delete if download_path.file?

            begin
              Vagrant::Util::Downloader.new(
                config.path, download_path
              ).download!
              yield download_path
            ensure
              download_path.delete
            end
          elsif config.path
            yield config.path
          else
            # We have an inline script. Create a temp file and handle it.
            file = Tempfile.new(['vagrant-powershell', '.ps1'])

            begin
              file.write(config.inline)
              file.fsync
              file.close
              yield file.path
            ensure
              file.close
            end
          end
        end
      end
    end
  end
end

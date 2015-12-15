#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#--------------------------------------------------------------------------
require 'log4r'
require 'pathname'
require 'vagrant/util/subprocess'
require 'vagrant/util/platform'

module VagrantPlugins
  module WinAzure
    module Action
      class Rdp
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure::action::rdp')
          @rdp_file = 'machine.rdp'
        end

        def call(env)
          if Vagrant::Util::Platform.windows?
            generate_rdp_file env[:machine]
            command = ['mstsc', @rdp_file]
            Vagrant::Util::Subprocess.execute(*command)
          elsif Vagrant::Util::Platform.darwin?
            generate_rdp_file env[:machine]
            command = ['open', @rdp_file]
            result = Vagrant::Util::Subprocess.execute(*command)

            if result.exit_code == 1
              raise result.stderr
            end
          elsif Vagrant::Util::Platform.linux?
            generate_rdp_file env[:machine]
            command = ['xfreerdp', @rdp_file]
            result = Vagrant::Util::Subprocess.execute(*command)

            if result.exit_code == 1
              raise result.stderr
            end
          else
            raise 'Unsupported operating system for RDP operation.'
          end

          @app.call(env)
        end

        def generate_rdp_file(machine)
          File.delete(@rdp_file) if File.exists?(@rdp_file)

          info = machine.provider.rdp_info

          rdp_options = {
            'drivestoredirect:s' => '*',
            'username:s' => machine.provider_config.vm_user,
            'prompt for credentials:i' => '1',
            'full address:s' => "#{info[:host]}:#{info[:port]}"
          }

          file = File.open(@rdp_file, 'w')
          rdp_options.each do |key, value|
            file.puts "#{key}:#{value}"
          end
          file.close
        end
      end
    end
  end
end

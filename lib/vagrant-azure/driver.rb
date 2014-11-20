#---------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#--------------------------------------------------------------------------
require 'json'
require "#{Vagrant::source_root}/plugins/providers/hyperv/driver"

module VagrantPlugins
  module WinAzure
    class Driver < VagrantPlugins::HyperV::Driver
      def initialize(machine)
        @id = machine.id
        @machine = machine
      end

      def ssh_info
        @ssh_info ||= @machine.provider.winrm_info
        @ssh_info[:username] ||= @machine.config.ssh.username
        @ssh_info[:password] ||= @machine.config.ssh.password
        @ssh_info
      end

      def remote_credentials
        @remote_credentials ||= {
          guest_ip: ssh_info[:host],
          guest_port: ssh_info[:port],
          username: ssh_info[:username],
          password: ssh_info[:password]
        }
      end

      def run_remote_ps(command, &block)
        @machine.communicate.execute(command) do |*args|
          block.call(args) unless block.nil?
        end
      end

      def upload(from, to)
        @machine.communicate.upload(from, to)
      end

      def check_winrm
        @machine.communicate.ready?
      end
    end
  end
end

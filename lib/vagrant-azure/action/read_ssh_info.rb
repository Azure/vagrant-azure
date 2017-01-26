# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.
require 'log4r'
require 'vagrant-azure/util/machine_id_helper'

module VagrantPlugins
  module Azure
    module Action
      class ReadSSHInfo
        include VagrantPlugins::Azure::Util::MachineIdHelper

        def initialize(app, _, port = 22)
          @app = app
          @port = port
          @logger = Log4r::Logger.new('vagrant_azure::action::read_ssh_info')
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env[:azure_arm_service], env)
          @app.call(env)
        end

        def read_ssh_info(azure, env)
          return nil if env[:machine].id.nil?
          parsed = parse_machine_id(env[:machine].id)
          public_ip = azure.network.public_ipaddresses.get(parsed[:group], "#{parsed[:name]}-vagrantPublicIP").value!.body

          {:host => public_ip.properties.dns_settings.fqdn, :port => 22}
        end
      end
    end
  end
end

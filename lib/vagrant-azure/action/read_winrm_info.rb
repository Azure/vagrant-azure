#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#--------------------------------------------------------------------------
require 'log4r'
require 'vagrant-azure/util/machine_id_helper'

module VagrantPlugins
  module Azure
    module Action
      class ReadWinrmInfo
        include VagrantPlugins::Azure::Util::MachineIdHelper

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure::action::read_winrm_info')
        end

        def call(env)
          if env[:machine].config.vm.guest == :windows
            env[:machine_winrm_info] = read_winrm_info(env[:azure_arm_service], env)
          end

          @app.call(env)
        end

        def read_winrm_info(azure, env)
          return nil if env[:machine].id.nil?
          parsed = parse_machine_id(env[:machine].id)
          public_ip = azure.network.public_ipaddresses.get(parsed[:group], "#{parsed[:name]}-vagrantPublicIP").value!.body
          env[:machine].config.winrm.ssl_peer_verification = false
          env[:machine].config.winrm.transport = :ssl

          {:host => public_ip.properties.dns_settings.fqdn, :port => 5986}
        end
      end
    end
  end
end

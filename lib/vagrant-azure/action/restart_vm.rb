# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.
require 'log4r'
require 'vagrant-azure/util/machine_id_helper'

module VagrantPlugins
  module Azure
    module Action
      class RestartVM
        include VagrantPlugins::Azure::Util::MachineIdHelper

        def initialize(app, _)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure::action::restart_vm')
        end

        def call(env)
          parsed = parse_machine_id(env[:machine].id)
          env[:ui].info(I18n.t('vagrant_azure.restarting', parsed))
          env[:azure_arm_service].compute.virtual_machines.restart(parsed[:group], parsed[:name])
          env[:ui].info(I18n.t('vagrant_azure.restarted', parsed))
          @app.call(env)
        end
      end
    end
  end
end

# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.
require 'log4r'
require 'vagrant-azure/util/machine_id_helper'

module VagrantPlugins
  module Azure
    module Action
      class TerminateInstance
        include VagrantPlugins::Azure::Util::MachineIdHelper

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure::action::terminate_instance')
        end

        def call(env)
          parsed = parse_machine_id(env[:machine].id)

          begin
            env[:ui].info(I18n.t('vagrant_azure.terminating', parsed))
            env[:azure_arm_service].resources.resource_groups.delete(parsed[:group])
          rescue MsRestAzure::AzureOperationError => ex
            unless ex.response.status == 404
              raise ex
            end
          end
          env[:ui].info(I18n.t('vagrant_azure.terminated', parsed))

          env[:machine].id = nil

          @app.call(env)
        end
      end
    end
  end
end

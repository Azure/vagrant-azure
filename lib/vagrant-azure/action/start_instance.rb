# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.
require 'log4r'
require 'vagrant-azure/util/machine_id_helper'
require 'vagrant-azure/util/vm_status_translator'
require 'vagrant/util/retryable'
require 'vagrant-azure/util/timer'
require 'vagrant-azure/util/vm_await'

module VagrantPlugins
  module Azure
    module Action
      # This starts a stopped instance
      class StartInstance
        include VagrantPlugins::Azure::Util::MachineIdHelper
        include VagrantPlugins::Azure::Util::VMStatusTranslator
        include VagrantPlugins::Azure::Util::VMAwait

        def initialize(app, _)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure::action::start_instance')
        end

        def call(env)
          env[:metrics] ||= {}

          parsed = parse_machine_id(env[:machine].id)
          azure = env[:azure_arm_service]
          env[:ui].info(I18n.t('vagrant_azure.starting', parsed))
          azure.compute.virtual_machines.start(parsed[:group], parsed[:name])

          # Wait for the instance to be ready first
          env[:metrics]['instance_ready_time'] = Util::Timer.time do

            env[:ui].info(I18n.t('vagrant_azure.waiting_for_ready'))

            task = await_true(env) do |vm|
              running?(vm.properties.instance_view.statuses)
            end

            if task.value
              env[:ui].info(I18n.t('vagrant_azure.started', parsed))
            else
              raise I18n.t('vagrant_azure.errors.failed_starting', parsed) unless env[:interrupted]
            end
          end

          @app.call(env)
        end
      end
    end
  end
end

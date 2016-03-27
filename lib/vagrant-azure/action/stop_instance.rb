# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.
require 'log4r'

# Bare bones basic implementation. This a work in progress in very early stages
module VagrantPlugins
  module Azure
    module Action
      class StopInstance

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure::action::stop_instance')
        end

        def call(env)
          if env[:machine].state.id == :StoppedDeallocated
            env[:ui].info(
              I18n.t('vagrant_azure.already_status', :status => 'stopped.')
            )
          else
            env[:machine].id =~ /@/
            VagrantPlugins::Azure::CLOUD_SERVICE_SEMAPHORE.synchronize do
              env[:ui].info(
                  I18n.t(
                      'vagrant_azure.stopping',
                      :vm_name => $`,
                      :cloud_service_name => $'
                  )
              )
              env[:azure_vm_service].shutdown_virtual_machine($`, $')
            end
          end
          @app.call(env)
        end
      end
    end
  end
end

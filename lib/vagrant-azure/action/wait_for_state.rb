#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------
require 'log4r'
require 'timeout'

module VagrantPlugins
  module WinAzure
    module Action
      class WaitForState
        def initialize(app, state, timeout)
          @app = app
          @state = state
          @timeout = timeout
          @logger = Log4r::Logger.new("vagrant_azure::action::wait_for_state")
        end

        def call(env)
          env[:result] = true

          if env[:machine].state.id == @state
            @logger.info(
              I18n.t('vagrant_azure.already_status', :status => @state)
            )
          else
            @logger.info("Waiting for machine to reache state #{@state}")

            begin
              Timeout.timeout(@timeout)  do
                until env[:machine].state.id == @state
                  sleep 5
                end
              end
            rescue Timeout::Error
              env[:result] = false # couldn't reach state in time
            end
          end

          @app.call(env)
        end
      end
    end
  end
end

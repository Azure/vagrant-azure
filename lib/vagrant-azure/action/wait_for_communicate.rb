#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
#--------------------------------------------------------------------------
require 'log4r'
require 'timeout'

module VagrantPlugins
  module WinAzure
    module Action
      class WaitForCommunicate
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_azure::action::wait_for_communicate")
        end

        def call(env)

          if !env[:interrupted]
              # Wait for SSH to be ready.
              env[:ui].info(I18n.t("vagrant_azure.waiting_for_ssh"))
              while true
                # If we're interrupted then just back out
                break if env[:interrupted]
                break if env[:machine].communicate.ready?
                sleep 5
              end

            # Ready and booted!
            env[:ui].info(I18n.t("vagrant_azure.ssh_ready"))
          end

          @app.call(env)
        end
      end
    end
  end
end

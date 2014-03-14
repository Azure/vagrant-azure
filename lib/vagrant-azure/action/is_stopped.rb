#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
#--------------------------------------------------------------------------

# This is a dummy implementation.
# TODO call Azure APIs to get the state

module VagrantPlugins
  module WinAzure
    module Action
      class IsStopped
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:result] = env[:machine].state.id == :StoppedDeallocated
          @app.call(env)
        end
      end
    end
  end
end

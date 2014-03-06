#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

# This is a dummy implementation.
# TODO call Azure APIs to get the state

module VagrantPlugins
  module WinAzure
    module Action
      class IsCreated
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:result] = env[:machine].state.id != :NotCreated
          @app.call(env)
        end
      end
    end
  end
end

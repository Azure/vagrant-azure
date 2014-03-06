#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------
module VagrantPlugins
  module WinAzure
    module Action
      class MessageNotCreated
        def initialize(app, env)
          @app = app
        end

        def env(env)
          env[:ui].info(I18n.t('vagrant_azure.not_created'))
          @app.call(env)
        end
      end
    end
  end
end

#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------
module VagrantPlugins
  module WinAzure
    module Action
      class MessageVMStarted
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:machine].id =~ /@/
          env[:ui].info(I18n.t('vagrant_azure.vm_started', :name => $`))
          @app.call(env)
        end
      end
    end
  end
end

# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.
module VagrantPlugins
  module Azure
    module Action
      class MessageWillNotDestroy
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t('vagrant_azure.will_not_destroy', name: env[:machine].name))
          @app.call(env)
        end
      end
    end
  end
end
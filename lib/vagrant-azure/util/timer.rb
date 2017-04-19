# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.

module VagrantPlugins
  module Azure
    module Util
      class Timer
        def self.time
          start_time = Time.now.to_f
          yield
          end_time = Time.now.to_f

          end_time - start_time
        end
      end
    end
  end
end
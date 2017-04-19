# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.

module VagrantPlugins
  module Azure
    module Util
      module ManagedImagedHelper
        ID_REGEX = /\/subscriptions\/(.+?)\/resourceGroups\/(.+?)\/providers\/Microsoft.Compute\/images\/(.+)/i

        def image_id_matches(image_id)
          image_id.match(ID_REGEX)
        end

        def image_id_captures(image_id)
          image_id_matches(image_id).captures
        end

        def valid_image_id?(image_id)
          match = image_id_matches(image_id)
          match && match.captures.count == 3 && !match.captures.any?(&:nil?)
        end
      end
    end
  end
end

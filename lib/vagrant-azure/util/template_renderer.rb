# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.

require "erb"

module VagrantPlugins
  module Azure
    module Util
      class TemplateRenderer
        class << self
          # Render a given template and return the result. This method optionally
          # takes a block which will be passed the renderer prior to rendering, which
          # allows the caller to set any view variables within the renderer itself.
          #
          # @return [String] Rendered template
          def render(*args)
            render_with(:render, *args)
          end

          # Method used internally to DRY out the other renderers. This method
          # creates and sets up the renderer before calling a specified method on it.
          def render_with(method, template, data = {})
            renderer = new(template, data)
            yield renderer if block_given?
            renderer.send(method.to_sym)
          end
        end

        def initialize(template, data = {})
          @data = data
          @template = template
        end

        def render
          str = File.read(full_template_path)
          ERB.new(str).result(OpenStruct.new(@data).instance_eval { binding })
        end

        # Returns the full path to the template, taking into accoun the gem directory
        # and adding the `.erb` extension to the end.
        #
        # @return [String]
        def full_template_path
          template_root.join("#{@template}.erb").to_s.squeeze("/")
        end

        def template_root
          Azure.source_root.join("templates")
        end
      end
    end
  end
end

# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.

module VagrantPlugins
  module Azure
    module Util
      module VMStatusTranslator

        PROVISIONING_STATES = [:provisioned, :deleting]
        POWER_STATES = [:running, :starting, :deallocating, :deallocated]

        def vm_status_to_state(status)
          code = status.code
          case
            when code == 'ProvisioningState/succeeded'
              :provisioned
            when code == 'ProvisioningState/deleting'
              :deleting
            when code == 'PowerState/running'
              :running
            when code == 'PowerState/stopping'
              :stopping
            when code == 'PowerState/stopped'
              :stopped
            when code == 'PowerState/starting'
              :starting
            when code == 'PowerState/deallocating'
              :deallocating
            when code == 'PowerState/deallocated'
              :deallocated
            else
              :unknown
          end
        end

        def power_state(statuses)
          vm_status_to_state(statuses.select{ |s| s.code.match(/PowerState/) }.last)
        end

        def running?(statuses)
          statuses.any?{ |s| vm_status_to_state(s) == :running }
        end

        def built?(statuses)
          statuses.any?{ |s| vm_status_to_state(s) == :provisioned }
        end

        def stopped?(statuses)
          statuses.any?{ |s| vm_status_to_state(s) == :stopped }
        end

        def stopping?(statuses)
          statuses.any?{ |s| vm_status_to_state(s) == :stopping }
        end

        def tearing_down?(statuses)
          statuses.any?{ |s| vm_status_to_state(s) == :deleting }
        end
      end
    end
  end
end
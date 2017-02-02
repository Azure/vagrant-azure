# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.
require 'log4r'
require 'vagrant'

module VagrantPlugins
  module Azure
    class Provider < Vagrant.plugin('2', :provider)

      def initialize(machine)
        @machine = machine

        # Load the driver
        machine_id_changed

        # turn off nfs functionality by default, so the machine will fall back to rsync by default
        @machine.config.nfs.functional = false
        @machine.config.winrm.password = @machine.provider_config.admin_password
        @machine.config.winrm.username = @machine.provider_config.admin_username
      end

      def action(name)
        # Attempt to get the action method from the Action class if it
        # exists, otherwise return nil to show that we don't support the
        # given action.
        action_method = "action_#{name}"
        return Action.send(action_method) if Action.respond_to?(action_method)
        nil
      end

      def ssh_info
        # Run a custom action called "read_ssh_info" which does what it
        # says and puts the resulting SSH info into the `:machine_ssh_info`
        # key in the environment.
        env = @machine.action('read_ssh_info')
        env[:machine_ssh_info]
      end

      def winrm_info
        env = @machine.action('read_winrm_info')
        env[:machine_winrm_info]
      end

      def state
        # Run a custom action we define called "read_state" which does what it
        # says. It puts the state in the `:machine_state_id` key in the env
        env = @machine.action('read_state')
        state_id = env[:machine_state_id]

        # Get the short and long description
        short = I18n.t("vagrant_azure.states.short_#{state_id}")
        long  = I18n.t("vagrant_azure.states.long_#{state_id}")

        # Return the MachineState object
        Vagrant::MachineState.new(state_id, short, long)
      end

      def to_s
        id = @machine.id.nil? ? 'new' : @machine.id
        "Azure (#{id})"
      end
    end
  end
end

#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#--------------------------------------------------------------------------
require 'pathname'

require 'vagrant/action/builder'

module VagrantPlugins
  module WinAzure
    module Action
      # Include the built-in modules so we can use them as top-level things.
      include Vagrant::Action::Builtin

      # This action is called to halt the remote machine.
      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :NotCreated do |env, b2|
            if env[:result]
              b2.use Message, I18n.t('vagrant_azure.not_created')
              next
            end

            b2.use ConnectAzure
            b2.use StopInstance
          end
        end
      end

      # This action is called to terminate the remote machine.
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, DestroyConfirm do |env, b2|
            if env[:result]
              b2.use ConfigValidate
              b.use Call, IsState, :NotCreated do |env2, b3|
                if env2[:result]
                  b3.use Message, I18n.t('vagrant_azure.not_created')
                  next
                end
              end

              b2.use ConnectAzure
              b2.use TerminateInstance
              b2.use ProvisionerCleanup if defined?(ProvisionerCleanup)
            else
              env[:machine].id =~ /@/
              b2.use Message, I18n.t(
                'vagrant_azure.will_not_destroy',
                :name => $`
              )
            end
          end
        end
      end

      # This action is called when `vagrant provision` is called.
      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConnectAzure
          b.use ConfigValidate
          b.use Call, IsState, :NotCreated do |env, b2|
            if env[:result]
              b2.use Message, I18n.t('vagrant_azure.not_created')
              next
            end

            env[:machine].id =~ /@/
            vm = env[:azure_vm_service].get_virtual_machine($`, $')
            if vm.os_type.to_sym == :Windows
              b2.use WinProvision
            else
              b2.use Provision
              b2.use SyncFolders
            end
          end
        end
      end

      # This action is called to read the SSH info of the machine. The
      # resulting state is expected to be put into the `:machine_ssh_info` key.
      def self.action_read_ssh_info
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectAzure
          b.use ReadSSHInfo, 22
        end
      end

      def self.action_read_rdp_info
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectAzure
          b.use ReadSSHInfo, 3389
        end
      end

      def self.action_read_winrm_info
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectAzure
          b.use ReadSSHInfo, 5986
        end
      end

      def self.action_read_state
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectAzure
          b.use ReadState
        end
      end

      # This action is called to SSH into the machine
      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :NotCreated do |env, b2|
            if env[:result]
              b2.use Message, I18n.t('vagrant_azure.not_created')
              next
            end

            b2.use SSHExec
          end
        end
      end

      def self.action_rdp
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :NotCreated do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t('vagrant_azure.not_created')
              next
            end

            b1.use Call, IsState, :ReadyRole do |env2, b2|
              if !env2[:result]
                b2.use Message, I18n.t('vagrant_azure.rdp_not_ready')
                next
              end

              b2.use Rdp
            end
          end
        end
      end

      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :NotCreated do |env, b2|
            if env[:result]
              b2.use Message, I18n.t('vagrant_azure.not_created')
              next
            end

            b2.use SSHRun
          end
        end
      end

      def self.action_prepare_boot
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, WaitForState, :ReadyRole do |env, b1|
            if env[:result]
              env[:machine].id =~ /@/
              b1.use Message, I18n.t(
                'vagrant_azure.vm_started', :name => $`
              )
              b1.use WaitForCommunicate
              b1.use action_provision
            end
          end
        end
      end

      # This action is called to bring the box up from nothing
      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use HandleBox
          b.use ConfigValidate
          b.use ConnectAzure

          b.use Call, IsState, :NotCreated do |env1, b1|
            if !env1[:result]
              b1.use Call, IsState, :StoppedDeallocated do |env2, b2|
                if env2[:result]
                  b2.use StartInstance # start this instance again
                  b2.use action_prepare_boot
                else
                  b2.use Message, I18n.t(
                    'vagrant_azure.already_status', :status => 'created'
                  )
                end
              end
            else
              b1.use RunInstance # Launch a new instance
              b1.use action_prepare_boot
            end
          end
        end
      end

      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectAzure
          b.use Call, IsState, :NotCreated do |env, b2|
            if env[:result]
              b2.use Message, I18n.t('vagrant_azure.not_created')
              next
            end

            b2.use action_halt
            b2.use Call, WaitForState, :StoppedDeallocated do |env2, b3|
              if env2[:result]
                env2[:machine].id =~ /@/
                b3.use Message, I18n.t('vagrant_azure.vm_stopped', name: $`)
                b3.use action_up
              else
                b3.use Message, 'Not able to stop the machine. Please retry.'
              end
            end
          end
        end
      end

      # The autoload farm
      action_root = Pathname.new(File.expand_path('../action', __FILE__))
      autoload :ConnectAzure, action_root.join('connect_azure')
      autoload :WinProvision, action_root.join('provision')
      autoload :Rdp, action_root.join('rdp')
      autoload :ReadSSHInfo, action_root.join('read_ssh_info')
      autoload :ReadState, action_root.join('read_state')
      autoload :RestartVM, action_root.join('restart_vm')
      autoload :RunInstance, action_root.join('run_instance')
      autoload :StartInstance, action_root.join('start_instance')
      autoload :StopInstance, action_root.join('stop_instance')
      autoload :SyncFolders, action_root.join('sync_folders')
      autoload :TerminateInstance, action_root.join('terminate_instance')
      # autoload :TimedProvision, action_root.join('timed_provision')
      # autoload :WarnNetworks, action_root.join('warn_networks')
      autoload :WaitForState, action_root.join('wait_for_state')
      autoload :WaitForCommunicate, action_root.join('wait_for_communicate')
    end
  end
end

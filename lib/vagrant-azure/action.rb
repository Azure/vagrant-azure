#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
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
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
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
              b.use Call, IsCreated do |env2, b3|
                if !env2[:result]
                  b3.use MessageNotCreated
                  next
                end
              end

              b2.use ConnectAzure
              b2.use TerminateInstance
              b2.use ProvisionerCleanup if defined?(ProvisionerCleanup)
            else
              b2.use MessageWillNotDestroy
            end
          end
        end
      end

      # This action is called when `vagrant provision` is called.
      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use Provision
            b2.use SyncFolders
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
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use SSHExec
          end
        end
      end

      def self.action_rdp
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env1, b1|
            if !env1[:result]
              b1.use MessageNotCreated
              next
            end

            b1.use Call, IsReady do |env2, b2|
              if !env2[:result]
                b2.use MessageRDPNotReady
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
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use SSHRun
          end
        end
      end

      def self.action_prepare_boot
        Vagrant::Action::Builder.new.tap do |b|
          b.use Provision
          b.use SyncFolders
          b.use WarnNetworks
        end
      end

      # This action is called to bring the box up from nothing
      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use HandleBoxUrl
          b.use ConfigValidate
          b.use ConnectAzure
          b.use Call, IsCreated do |env1, b1|
            if env1[:result]
              b1.use Call, IsStopped do |env2, b2|
                if env2[:result]
                  # b2.use action_prepare_boot
                  b2.use StartInstance # restart this instance
                  b2.use Call, WaitForState, :ReadyRole, 300 do |env3, b3|
                    if env3[:result]
                      b3.use MessageVMStarted
                    end
                  end
                else
                  b2.use MessageAlreadyCreated
                end
              end
            else
              # b1.use action_prepare_boot
              b1.use RunInstance # Launch a new instance
              b1.use Call, WaitForState, :ReadyRole, 300 do |env2, b2|
                if env2[:result]
                  b2.use MessageVMStarted
                end
              end
            end
          end
        end
      end

      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectAzure
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use RestartVM
            b2.use Call, WaitForState, :ReadyRole, 300 do |env2, b3|
              if env2[:result]
                b3.use MessageVMStarted
              end
            end
          end
        end
      end

      # The autoload farm
      action_root = Pathname.new(File.expand_path('../action', __FILE__))
      autoload :ConnectAzure, action_root.join('connect_azure')
      autoload :IsCreated, action_root.join('is_created')
      autoload :IsReady, action_root.join('is_ready')
      autoload :IsStopped, action_root.join('is_stopped')
      autoload :MessageAlreadyCreated, action_root.join('message_already_created')
      autoload :MessageNotCreated, action_root.join('message_not_created')
      autoload :MessageRDPNotReady, action_root.join('message_rdp_not_ready')
      autoload :MessageVMStarted, action_root.join('message_vm_started')
      autoload :MessageWillNotDestroy, action_root.join('message_will_not_destroy')
      autoload :Rdp, action_root.join('rdp')
      autoload :ReadSSHInfo, action_root.join('read_ssh_info')
      autoload :ReadState, action_root.join('read_state')
      autoload :RestartVM, action_root.join('restart_vm')
      autoload :RunInstance, action_root.join('run_instance')
      autoload :StartInstance, action_root.join('start_instance')
      autoload :StopInstance, action_root.join('stop_instance')
      # autoload :SyncFolders, action_root.join('sync_folders')
      autoload :TerminateInstance, action_root.join('terminate_instance')
      # autoload :TimedProvision, action_root.join('timed_provision')
      # autoload :WarnNetworks, action_root.join('warn_networks')
      autoload :WaitForState, action_root.join('wait_for_state')
    end
  end
end

#---------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------
require 'log4r'
require 'json'
require 'azure'

require 'vagrant/util/retryable'

module VagrantPlugins
  module WinAzure
    module Action
      class RunInstance
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure::action::run_instance')
        end

        def call(env)
          config = env[:machine].provider_config

          # Add the mandatory parameters to the params hash
          params = {
            vm_name: config.vm_name,
            vm_user: config.vm_user,
            image: config.vm_image
          }

          # Add the optional parameters if they not nil
          params[:password] = config.vm_password unless config.vm_password.nil?
          params[:location] = config.vm_location unless config.vm_location.nil?
          params[:affinity_group] = config.vm_affinity_group unless config.vm_affinity_group.nil?

          options = {
            storage_account_name: config.storage_acct_name,
            cloud_service_name: config.cloud_service_name,
            deployment_name: config.deployment_name,
            tcp_endpoints: config.tcp_endpoints,
            private_key_file: config.ssh_private_key_file,
            certificate_file: config.ssh_certificate_file,
            ssh_port: config.ssh_port,
            vm_size: config.vm_size,
            winrm_transport: config.winrm_transport,
            availability_set_name: config.availability_set_name
          }

          add_role = config.add_role

          env[:ui].info(params.inspect)
          env[:ui].info(options.inspect)
          env[:ui].info("Add Role? - #{add_role}")

          server = env[:azure_vm_service].create_virtual_machine(
            params, options, add_role
          )

          # TODO: Exception/Error Handling

          if server.instance_of? String
            env[:ui].info "Server not created. Error is: #{server}"
            raise "#{server}"
          end

          env[:machine].id = "#{server.vm_name}@#{server.cloud_service_name}"

          @app.call(env)
        end
      end
    end
  end
end

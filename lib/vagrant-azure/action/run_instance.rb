#---------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#--------------------------------------------------------------------------
require 'log4r'
require 'json'
require 'azure'

require 'vagrant/util/retryable'

CLOUD_SERVICE_SEMAPHORE = Mutex.new

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

          # Add the mandatory parameters and options
          params = {
            vm_name: config.vm_name,
            vm_user: config.vm_user,
            image: config.vm_image
          }

          options = {
            cloud_service_name: config.cloud_service_name
          }


          # Add the optional parameters and options if not nil
          params[:password] = config.vm_password unless config.vm_password.nil?
          params[:location] = config.vm_location unless config.vm_location.nil?
          params[:affinity_group] = config.vm_affinity_group unless \
            config.vm_affinity_group.nil?

          options[:storage_account_name] = config.storage_acct_name unless \
            config.storage_acct_name.nil?
          options[:deployment_name] = config.deployment_name unless \
            config.deployment_name.nil?
          options[:tcp_endpoints] = config.tcp_endpoints unless \
            config.tcp_endpoints.nil?
          options[:private_key_file] = config.ssh_private_key_file unless \
            config.ssh_private_key_file.nil?
          options[:certificate_file] = config.ssh_certificate_file unless \
            config.ssh_certificate_file.nil?
          options[:ssh_port] = config.ssh_port unless \
            config.ssh_port.nil?
          options[:vm_size] = config.vm_size unless \
            config.vm_size.nil?
          options[:winrm_transport] = config.winrm_transport unless \
            config.winrm_transport.nil?
          options[:winrm_http_port] = config.winrm_http_port unless \
            config.winrm_http_port.nil?
          options[:winrm_https_port] = config.winrm_https_port unless \
            config.winrm_https_port.nil?
          options[:availability_set_name] = config.availability_set_name unless \
            config.availability_set_name.nil?

          add_role = false

          env[:ui].info(params.inspect)
          env[:ui].info(options.inspect)

          server = CLOUD_SERVICE_SEMAPHORE.synchronize do
            # Check if the cloud service exists and if yes, does it contain
            # a deployment.
            if config.cloud_service_name && !config.cloud_service_name.empty?
              begin
                cloud_service = ManagementHttpRequest.new(
                    :get,
                    "/services/hostedservices/#{config.cloud_service_name}?embed-detail=true"
                ).call

                deployments = cloud_service.css 'HostedService Deployments Deployment'

                # Lets see if any deployments exist. Set add_role = true if yes.
                # We're not worried about deployment slots, because the SDK has
                # hard coded 'Production' as deployment slot and you can have only
                # one deployment per deployment slot.
                add_role = deployments.length == 1
              rescue Exception => e
                add_role = false
              end
            end
            env[:ui].info("Add Role? - #{add_role}")

            env[:azure_vm_service].create_virtual_machine(params, options, add_role)
          end

          if server.nil?
            raise Errors::CreateVMFailure
          end

          # The Ruby SDK returns any exception encountered on create virtual
          # machine as a string.

          if server.instance_of? String
            raise Errors::ServerNotCreated, message: server
          end

          env[:machine].id = "#{server.vm_name}@#{server.cloud_service_name}"

          @app.call(env)
        end
      end
    end
  end
end

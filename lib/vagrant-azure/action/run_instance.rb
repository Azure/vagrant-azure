# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.
require 'log4r'
require 'json'
require 'azure_mgmt_resources'
require 'vagrant/util/template_renderer'
require 'vagrant-azure/util/timer'
require 'vagrant-azure/util/machine_id_helper'
require 'haikunator'

module VagrantPlugins
  module Azure
    module Action
      class RunInstance
        include Vagrant::Util::Retryable
        include VagrantPlugins::Azure::Util::MachineIdHelper

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_azure::action::run_instance')
        end

        def call(env)
          # Initialize metrics if they haven't been
          env[:metrics] ||= {}

          machine = env[:machine]

          # Get the configs
          config                    = machine.provider_config
          endpoint                  = config.endpoint
          resource_group_name       = config.resource_group_name
          location                  = config.location
          admin_user_name           = machine.config.ssh.username
          vm_name                   = config.vm_name
          vm_password               = config.vm_password
          vm_size                   = config.vm_size
          vm_image_urn              = config.vm_image_urn
          virtual_network_name      = config.virtual_network_name
          subnet_name               = config.subnet_name
          tcp_endpoints             = config.tcp_endpoints
          availability_set_name     = config.availability_set_name

          # Launch!
          env[:ui].info(I18n.t('vagrant_azure.launching_instance'))
          env[:ui].info(" -- Management Endpoint: #{endpoint}")
          env[:ui].info(" -- Subscription Id: #{config.subscription_id}")
          env[:ui].info(" -- Resource Group Name: #{resource_group_name}")
          env[:ui].info(" -- Location: #{location}")
          env[:ui].info(" -- Admin User Name: #{admin_user_name}") if admin_user_name
          env[:ui].info(" -- VM Name: #{vm_name}")
          env[:ui].info(" -- VM Size: #{vm_size}")
          env[:ui].info(" -- Image URN: #{vm_image_urn}")
          env[:ui].info(" -- Virtual Network Name: #{virtual_network_name}") if virtual_network_name
          env[:ui].info(" -- Subnet Name: #{subnet_name}") if subnet_name
          env[:ui].info(" -- TCP Endpoints: #{tcp_endpoints}") if tcp_endpoints
          env[:ui].info(" -- Availability Set Name: #{availability_set_name}") if availability_set_name

          image_publisher, image_offer, image_sku, image_version = vm_image_urn.split(':')

          azure = env[:azure_arm_service]
          image_details = nil
          env[:metrics]['get_image_details'] = Util::Timer.time do
            image_details = get_image_details(azure, location, image_publisher, image_offer, image_sku, image_version)
          end
          @logger.info("Time to fetch os image details: #{env[:metrics]['get_image_details']}")

          deployment_params = {
            adminUserName:        admin_user_name,
            dnsLabelPrefix:       Haikunator.haikunate(100),
            vmSize:               vm_size,
            vmName:               vm_name,
            imagePublisher:       image_publisher,
            imageOffer:           image_offer,
            imageSku:             image_sku,
            imageVersion:         image_version,
            subnetName:           subnet_name,
            virtualNetworkName:   virtual_network_name
          }

          if get_image_os(image_details) != 'Windows'
            private_key_paths = machine.config.ssh.private_key_path
            if private_key_paths.nil? || private_key_paths.empty?
              raise I18n.t('vagrant_azure.private_key_not_specified')
            end

            paths_to_pub = private_key_paths.map{ |k| File.expand_path( k + '.pub') }.select{ |p| File.exists?(p) }
            raise I18n.t('vagrant_azure.public_key_path_private_key', private_key_paths.join(', ')) if paths_to_pub.empty?
            deployment_params.merge!(sshKeyData: File.read(paths_to_pub.first))
          end

          template_params = {
              operating_system:   get_image_os(image_details)
          }

          env[:ui].info(" -- Create or Update of Resource Group: #{resource_group_name}")
          env[:metrics]['put_resource_group'] = Util::Timer.time do
            put_resource_group(azure, resource_group_name, location)
          end
          @logger.info("Time to create resource group: #{env[:metrics]['put_resource_group']}")

          deployment_params = build_deployment_params(template_params, deployment_params.reject{|_,v| v.nil?})

          env[:ui].info('Starting deployment')
          env[:metrics]['deployment_time'] = Util::Timer.time do
            put_deployment(azure, resource_group_name, deployment_params)
          end
          env[:ui].info('Finished deploying')

          # Immediately save the ID since it is created at this point.
          env[:machine].id = serialize_machine_id(resource_group_name, vm_name, location)

          @logger.info("Time to deploy: #{env[:metrics]['deployment_time']}")
          unless env[:interrupted]
            env[:metrics]['instance_ssh_time'] = Util::Timer.time do
              # Wait for SSH to be ready.
              env[:ui].info(I18n.t('vagrant_azure.waiting_for_ssh'))
              network_ready_retries = 0
              network_ready_retries_max = 10
              while true
                break if env[:interrupted]
                begin
                  break if env[:machine].communicate.ready?
                rescue Exception => e
                  if network_ready_retries < network_ready_retries_max
                    network_ready_retries += 1
                    @logger.warn(I18n.t('vagrant_azure.waiting_for_ssh, retrying'))
                  else
                    raise e
                  end
                end
                sleep 2
              end
            end

            @logger.info("Time for SSH ready: #{env[:metrics]['instance_ssh_time']}")

            # Ready and booted!
            env[:ui].info(I18n.t('vagrant_azure.ready'))
          end

          # Terminate the instance if we were interrupted
          terminate(env) if env[:interrupted]

          @app.call(env)
        end

        def get_image_os(image_details)
          image_details.os_disk_image.operating_system
        end

        def get_image_details(azure, location, publisher, offer, sku, version)
          if version == 'latest'
            latest = azure.compute.virtual_machine_images.list(location, publisher, offer, sku)
            azure.compute.virtual_machine_images.get(location, publisher, offer, sku, latest.name)
          else
            azure.compute.virtual_machine_images.get(location, publisher, offer, sku, version)
          end
        end

        def put_deployment(azure, rg_name, params)
          azure.resources.deployments.create_or_update(rg_name, 'vagrant', params)
        end

        def put_resource_group(azure, name, location)
          params = ::Azure::ARM::Resources::Models::ResourceGroup.new.tap do |rg|
            rg.location = location
          end

          azure.resources.resource_groups.create_or_update(name, params)
        end

        # This method generates the deployment template
        def render_deployment_template(options)
          Vagrant::Util::TemplateRenderer.render('arm/deployment.json', options.merge(template_root: template_root))
        end

        def build_deployment_params(template_params, deployment_params)
          params = ::Azure::ARM::Resources::Models::Deployment.new
          params.properties = ::Azure::ARM::Resources::Models::DeploymentProperties.new
          params.properties.template = JSON.parse(render_deployment_template(template_params))
          params.properties.mode = ::Azure::ARM::Resources::Models::DeploymentMode::Incremental
          params.properties.parameters = build_parameters(deployment_params)
          params
        end

        def build_parameters(options)
          Hash[*options.map{ |k, v| [k,  {value: v}] }.flatten]
        end

        # Used to find the base location of aws-vagrant templates
        def template_root
          Azure.source_root.join('templates')
        end

        def terminate(env)
          destroy_env = env.dup
          destroy_env.delete(:interrupted)
          destroy_env[:config_validate] = false
          destroy_env[:force_confirm_destroy] = true
          env[:action_runner].run(Action.action_destroy, destroy_env)
        end
      end
    end
  end
end

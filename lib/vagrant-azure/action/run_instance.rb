# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.
require "log4r"
require "json"
require "azure_mgmt_resources"
require "vagrant-azure/util/machine_id_helper"
require "vagrant-azure/util/template_renderer"
require "vagrant-azure/util/managed_image_helper"
require "vagrant-azure/util/timer"
require "haikunator"

module VagrantPlugins
  module Azure
    module Action
      class RunInstance
        include Vagrant::Util::Retryable
        include VagrantPlugins::Azure::Util::MachineIdHelper
        include VagrantPlugins::Azure::Util::ManagedImagedHelper

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_azure::action::run_instance")
        end

        def call(env)
          # Initialize metrics if they haven't been
          env[:metrics] ||= {}

          machine = env[:machine]

          # Get the configs
          config                         = machine.provider_config

          config.dns_name ||= config.vm_name
          config.nsg_name ||= config.vm_name

          endpoint                       = config.endpoint
          resource_group_name            = config.resource_group_name
          location                       = config.location
          ssh_user_name                  = machine.config.ssh.username
          vm_name                        = config.vm_name
          vm_storage_account_type        = config.vm_storage_account_type
          vm_size                        = config.vm_size
          vm_image_urn                   = config.vm_image_urn
          vm_vhd_uri                     = config.vm_vhd_uri
          vm_operating_system            = config.vm_operating_system
          vm_managed_image_id            = config.vm_managed_image_id
          virtual_network_name           = config.virtual_network_name
          subnet_name                    = config.subnet_name
          tcp_endpoints                  = config.tcp_endpoints
          availability_set_name          = config.availability_set_name
          admin_user_name                = config.admin_username
          admin_password                 = config.admin_password
          winrm_port                     = machine.config.winrm.port
          winrm_install_self_signed_cert = config.winrm_install_self_signed_cert
          dns_label_prefix               = config.dns_name
          nsg_label_prefix               = config.nsg_name

          # Launch!
          env[:ui].info(I18n.t('vagrant_azure.launching_instance'))
          env[:ui].info(" -- Management Endpoint: #{endpoint}")
          env[:ui].info(" -- Subscription Id: #{config.subscription_id}")
          env[:ui].info(" -- Resource Group Name: #{resource_group_name}")
          env[:ui].info(" -- Location: #{location}")
          env[:ui].info(" -- SSH User Name: #{ssh_user_name}") if ssh_user_name
          env[:ui].info(" -- Admin Username: #{admin_user_name}") if admin_user_name
          env[:ui].info(" -- VM Name: #{vm_name}")
          env[:ui].info(" -- VM Storage Account Type: #{vm_storage_account_type}")
          env[:ui].info(" -- VM Size: #{vm_size}")

          if !vm_vhd_uri.nil?
            env[:ui].info(" -- Custom VHD URI: #{vm_vhd_uri}")
            env[:ui].info(" -- Custom OS: #{vm_operating_system}")
          elsif !vm_managed_image_id.nil?
            env[:ui].info(" -- Managed Image Id: #{vm_managed_image_id}")
          else
            env[:ui].info(" -- Image URN: #{vm_image_urn}")
          end

          env[:ui].info(" -- Virtual Network Name: #{virtual_network_name}") if virtual_network_name
          env[:ui].info(" -- Subnet Name: #{subnet_name}") if subnet_name
          env[:ui].info(" -- TCP Endpoints: #{tcp_endpoints}") if tcp_endpoints
          env[:ui].info(" -- Availability Set Name: #{availability_set_name}") if availability_set_name
          env[:ui].info(" -- DNS Label Prefix: #{dns_label_prefix}")

          image_publisher, image_offer, image_sku, image_version = vm_image_urn.split(":")

          azure = env[:azure_arm_service]
          @logger.info("Time to fetch os image details: #{env[:metrics]["get_image_details"]}")

          deployment_params = {
            dnsLabelPrefix:       dns_label_prefix,
            nsgLabelPrefix:       nsg_label_prefix,
            vmSize:               vm_size,
            storageAccountType:   vm_storage_account_type,
            vmName:               vm_name,
            subnetName:           subnet_name,
            virtualNetworkName:   virtual_network_name,
          }

          # we need to pass different parameters depending upon the OS
          # if custom image, then require vm_operating_system
          operating_system = if vm_vhd_uri
                               vm_operating_system
                             elsif vm_managed_image_id
                               get_managed_image_os(azure, vm_managed_image_id)
                             else
                               get_image_os(azure, location, image_publisher, image_offer, image_sku, image_version)
                             end

          template_params = {
            availability_set_name:          availability_set_name,
            winrm_install_self_signed_cert: winrm_install_self_signed_cert,
            winrm_port:                     winrm_port,
            dns_label_prefix:               dns_label_prefix,
            nsg_label_prefix:               nsg_label_prefix,
            location:                       location,
            image_publisher:                image_publisher,
            image_offer:                    image_offer,
            image_sku:                      image_sku,
            image_version:                  image_version,
            vhd_uri:                        vm_vhd_uri,
            operating_system:               operating_system,
            data_disks:                     config.data_disks
          }

          if operating_system != "Windows"
            private_key_paths = machine.config.ssh.private_key_path
            if private_key_paths.nil? || private_key_paths.empty?
              raise I18n.t('vagrant_azure.private_key_not_specified')
            end

            paths_to_pub = private_key_paths.map { |k| File.expand_path(k + ".pub") }.select { |p| File.exists?(p) }
            raise I18n.t('vagrant_azure.public_key_path_private_key', private_key_paths.join(', ')) if paths_to_pub.empty?
            deployment_params.merge!(adminUsername:  ssh_user_name)
            deployment_params.merge!(sshKeyData: File.read(paths_to_pub.first))
            communicator_message = "vagrant_azure.waiting_for_ssh"
          else
            env[:machine].config.vm.communicator = :winrm
            machine.config.winrm.port = winrm_port
            machine.config.winrm.username = admin_user_name
            machine.config.winrm.password = admin_password
            communicator_message = "vagrant_azure.waiting_for_winrm"
            windows_params = {
              adminUsername:  admin_user_name,
              adminPassword:  admin_password,
              winRmPort:      winrm_port
            }
            deployment_params.merge!(windows_params)
          end

          template_params.merge!(endpoints: get_endpoints(tcp_endpoints))

          env[:ui].info(" -- Create or Update of Resource Group: #{resource_group_name}")
          env[:metrics]["put_resource_group"] = Util::Timer.time do
            put_resource_group(azure, resource_group_name, location)
          end
          @logger.info("Time to create resource group: #{env[:metrics]['put_resource_group']}")

          deployment_params = build_deployment_params(template_params, deployment_params.reject { |_, v| v.nil? })

          env[:ui].info(" -- Starting deployment")
          env[:metrics]["deployment_time"] = Util::Timer.time do
            put_deployment(azure, resource_group_name, deployment_params)
          end
          env[:ui].info(" -- Finished deploying")

          # Immediately save the ID since it is created at this point.
          env[:machine].id = serialize_machine_id(resource_group_name, vm_name, location)

          @logger.info("Time to deploy: #{env[:metrics]['deployment_time']}")
          unless env[:interrupted]
            env[:metrics]["instance_ssh_time"] = Util::Timer.time do
              # Wait for SSH/WinRM to be ready.
              env[:ui].info(I18n.t(communicator_message))
              network_ready_retries = 0
              network_ready_retries_max = 10
              while true
                break if env[:interrupted]
                begin
                  break if env[:machine].communicate.ready?
                rescue Exception => e
                  if network_ready_retries < network_ready_retries_max
                    network_ready_retries += 1
                    @logger.warn(I18n.t("#{communicator_message}, retrying"))
                  else
                    raise e
                  end
                end
                sleep 2
              end
            end

            @logger.info("Time for SSH/WinRM ready: #{env[:metrics]['instance_ssh_time']}")

            # Ready and booted!
            env[:ui].info(I18n.t('vagrant_azure.ready')) unless env[:interrupted]
          end

          # Terminate the instance if we were interrupted
          terminate(env) if env[:interrupted]

          @app.call(env)
        end

        def get_endpoints(tcp_endpoints)
          endpoints = [8443]
          unless tcp_endpoints.nil?
            if tcp_endpoints.is_a?(Array)
              # https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-nsg#Nsg-rules
              if tcp_endpoints.length + 133 > 4096
                raise I18n.t("vagrant_azure.too_many_tcp_endpoints", count: tcp_endpoints.length)
              end
              endpoints = tcp_endpoints
            elsif tcp_endpoints.is_a?(String) || (tcp_endpoints.is_a?(Integer) && tcp_endpoints > 0)
              endpoints = [tcp_endpoints]
            else
              raise I18n.t("vagrant_azure.unknown_type_as_tcp_endpoints", input: tcp_endpoints)
            end
          end
          endpoints
        end

        def get_image_os(azure, location, publisher, offer, sku, version)
          image_details = get_image_details(azure, location, publisher, offer, sku, version)
          image_details.os_disk_image.operating_system
        end

        def get_managed_image_os(azure, image_id)
          _, group, name = image_id_captures(image_id)
          image_details = azure.compute.images.get(group, name)
          image_details.storage_profile.os_disk.os_type
        end

        def get_image_details(azure, location, publisher, offer, sku, version)
          if version == "latest"
            images = azure.compute.virtual_machine_images.list(location, publisher, offer, sku)
            latest = images.sort_by(&:name).last
            if latest.nil?
              raise "Unrecognized location, publisher, offer, sku, version combination: #{location}, #{publisher}, #{offer}, #{sku}, latest. Run `az vm image list` to ensure the image is available."
            end
            azure.compute.virtual_machine_images.get(location, publisher, offer, sku, latest.name)
          else
            azure.compute.virtual_machine_images.get(location, publisher, offer, sku, version)
          end
        end

        def put_deployment(azure, rg_name, params)
          deployment_name = "vagrant_#{Time.now.getutc.strftime('%Y%m%d%H%M%S')}"
          azure.resources.deployments.create_or_update(rg_name, deployment_name, params)
        end

        def put_resource_group(azure, name, location)
          params = ::Azure::ARM::Resources::Models::ResourceGroup.new.tap do |rg|
            rg.location = location
          end

          azure.resources.resource_groups.create_or_update(name, params)
        end

        # This method generates the deployment template
        def render_deployment_template(options)
          self_signed_cert_resource = nil
          if options[:operating_system] == "Windows" && options[:winrm_install_self_signed_cert]
            setup_winrm_powershell = VagrantPlugins::Azure::Util::TemplateRenderer.render("arm/setup-winrm.ps1", options)
            encoded_setup_winrm_powershell = setup_winrm_powershell.
              gsub("'", "', variables('singleQuote'), '").
              gsub("\r\n", "\n").
              gsub("\n", "; ")
            self_signed_cert_resource = VagrantPlugins::Azure::Util::TemplateRenderer.render("arm/selfsignedcert.json", options.merge({setup_winrm_powershell: encoded_setup_winrm_powershell}))
          end
          VagrantPlugins::Azure::Util::TemplateRenderer.render("arm/deployment.json", options.merge({self_signed_cert_resource: self_signed_cert_resource}))
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
          Hash[*options.map { |k, v| [k, { value: v } ] }.flatten]
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

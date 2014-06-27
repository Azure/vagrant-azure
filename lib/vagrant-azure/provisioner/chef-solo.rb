#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#--------------------------------------------------------------------------

require "fileutils"
require "tempfile"

module VagrantPlugins
  module WinAzure
    module Provisioner
      class ChefSolo
        attr_reader :provisioner

        def initialize(env)
          @env = env
          @provisioner = env[:provisioner]
        end

        def provision_for_windows
          # Copy the chef cookbooks roles data bags and environment folders to Guest
          copy_folder_to_guest(provisioner.cookbook_folders)
          copy_folder_to_guest(provisioner.role_folders)
          copy_folder_to_guest(provisioner.data_bags_folders)
          copy_folder_to_guest(provisioner.environments_folders)

          # Upload Encrypted data bag
          upload_encrypted_data_bag_secret if config.encrypted_data_bag_secret_key_path
          setup_json
          setup_solo_config
          run_chef_solo

          # TODO
          # delete_encrypted_data_bag_secret
        end

        def setup_json
          @env[:machine].env.ui.info I18n.t("vagrant.provisioners.chef.json")

          # Get the JSON that we're going to expose to Chef
          json = config.json
          json[:run_list] = config.run_list if !config.run_list.empty?
          json = JSON.pretty_generate(json)

          # Create a temporary file to store the data so we
          # can upload it
          temp = Tempfile.new("vagrant")
          temp.write(json)
          temp.close

          remote_file = File.join(config.provisioning_path, "dna.json")
          @env[:machine].provider.driver.upload(temp.path, remote_file)
        end

        def setup_solo_config
          cookbooks_path = guest_paths(provisioner.cookbook_folders)
          roles_path = guest_paths(provisioner.role_folders)
          data_bags_path = guest_paths(provisioner.data_bags_folders).first
          environments_path = guest_paths(provisioner.environments_folders).first
          source_path = "#{VagrantPlugins::WinAzure.source_root}"
          template_path = source_path + "/templates/provisioners/chef-solo/solo"
          setup_config(template_path, "solo.rb", {
            :cookbooks_path => cookbooks_path,
            :recipe_url => config.recipe_url,
            :roles_path => roles_path,
            :data_bags_path => data_bags_path,
            :environments_path => environments_path
          })
        end

        def setup_config(template, filename, template_vars)
          # If we have custom configuration, upload it
          remote_custom_config_path = nil
          if config.custom_config_path
            expanded = File.expand_path(
              config.custom_config_path, @machine.env.root_path)
            remote_custom_config_path = File.join(
              config.provisioning_path, "custom-config.rb")

            @env[:machine].provider.driver.upload(expanded, remote_custom_config_path)
          end

          config_file = Vagrant::Util::TemplateRenderer.render(template, {
            :custom_configuration => remote_custom_config_path,
            :file_cache_path => config.file_cache_path,
            :file_backup_path => config.file_backup_path,
            :log_level        => config.log_level.to_sym,
            :verbose_logging  => config.verbose_logging,
            :http_proxy       => config.http_proxy,
            :http_proxy_user  => config.http_proxy_user,
            :http_proxy_pass  => config.http_proxy_pass,
            :https_proxy      => config.https_proxy,
            :https_proxy_user => config.https_proxy_user,
            :https_proxy_pass => config.https_proxy_pass,
            :no_proxy         => config.no_proxy,
            :formatter        => config.formatter
          }.merge(template_vars))

          # Create a temporary file to store the data so we can upload it
          temp = Tempfile.new("vagrant")
          temp.write(config_file)
          temp.close

          remote_file = File.join(config.provisioning_path, filename)
          @env[:machine].provider.driver.upload(temp.path, remote_file)
        end

        def run_chef_solo
          if config.run_list && config.run_list.empty?
            @env[:machine].ui.warn(I18n.t("vagrant.chef_run_list_empty"))
          end

          options = [
            "-c #{config.provisioning_path}/solo.rb",
            "-j #{config.provisioning_path}/dna.json"
          ]

          command_env = config.binary_env ? "#{config.binary_env} " : ""
          command_args = config.arguments ? " #{config.arguments}" : ""
          command = "#{command_env}#{chef_binary_path("chef-solo")} " +
            "#{options.join(" ")} #{command_args}"
          config.attempts.times do |attempt|
            if attempt == 0
              @env[:machine].env.ui.info I18n.t("vagrant.provisioners.chef.running_solo")
            else
              @env[:machine].env.ui.info I18n.t("vagrant.provisioners.chef.running_solo_again")
            end

            command

            @env[:machine].provider.driver.run_remote_ps(command) do |type, data|
              # Output the data with the proper color based on the stream.
              if (type == :stdout || type == :stderr)
                @env[:ui].detail data
              end
            end
          end

        end

        def upload_encrypted_data_bag_secret
          @machine.env.ui.info I18n.t("vagrant.provisioners.chef.upload_encrypted_data_bag_secret_key")
          @env[:machine].provider.driver.upload(encrypted_data_bag_secret_key_path,
                        config.encrypted_data_bag_secret)
        end

        def encrypted_data_bag_secret_key_path
          File.expand_path(config.encrypted_data_bag_secret_key_path, @env[:machine].env.root_path)
        end

        def config
          provisioner.config
        end

        def guest_paths(folders)
          folders.map { |parts| parts[2] }
        end

        # Returns the path to the Chef binary, taking into account the
        # `binary_path` configuration option.
        def chef_binary_path(binary)
          return binary if !config.binary_path
          return File.join(config.binary_path, binary)
        end

        def copy_folder_to_guest(folders)
          folders.each do |type, local_path, remote_path|
            if type == :host
              @env[:machine].provider.driver.upload(local_path, remote_path)
            end
          end
        end

      end
    end
  end
end

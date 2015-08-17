#--------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#--------------------------------------------------------------------------
require 'vagrant'
require 'azure'

module VagrantPlugins
  module WinAzure
    class Config < Vagrant.plugin('2', :config)

      attr_accessor :mgmt_certificate
      attr_accessor :mgmt_endpoint
      attr_accessor :subscription_id
      attr_accessor :storage_acct_name
      attr_accessor :storage_access_key

      attr_accessor :vm_name
      attr_accessor :vm_user
      attr_accessor :vm_password
      attr_accessor :vm_image
      attr_accessor :vm_location
      attr_accessor :vm_affinity_group
      attr_accessor :vm_virtual_network_name

      attr_accessor :cloud_service_name
      attr_accessor :deployment_name
      attr_accessor :tcp_endpoints

      # ssh_private_key and ssh_certificate_file is overly specific and probably should be deprecated in favor of
      # private_key_file and certificate_file as they are in Azure ruby sdk.
      # This is here to not break compatibility with previous versions.
      attr_accessor :private_key_file
      alias :ssh_private_key_file :private_key_file
      alias :ssh_private_key_file= :private_key_file=

      attr_accessor :ssh_port
      attr_accessor :vm_size
      attr_accessor :winrm_transport
      attr_accessor :winrm_http_port
      attr_accessor :winrm_https_port
      attr_accessor :availability_set_name

      attr_accessor :state_read_timeout

      def initialize
        @storage_acct_name = UNSET_VALUE
        @storage_access_key = UNSET_VALUE
        @mgmt_certificate = UNSET_VALUE
        @mgmt_endpoint = UNSET_VALUE
        @subscription_id = UNSET_VALUE

        @vm_name = UNSET_VALUE
        @vm_user = UNSET_VALUE
        @vm_password = UNSET_VALUE
        @vm_image = UNSET_VALUE
        @vm_location = UNSET_VALUE
        @vm_affinity_group = UNSET_VALUE
        @vm_virtual_network_name = UNSET_VALUE

        @cloud_service_name = UNSET_VALUE
        @deployment_name = UNSET_VALUE
        @tcp_endpoints = UNSET_VALUE
        @private_key_file = UNSET_VALUE
        @ssh_port = UNSET_VALUE
        @vm_size = UNSET_VALUE
        @winrm_transport = UNSET_VALUE
        @winrm_http_port = UNSET_VALUE
        @winrm_https_port = UNSET_VALUE
        @availability_set_name = UNSET_VALUE
        @state_read_timeout = UNSET_VALUE
      end

      def finalize!
        @storage_acct_name = ENV['AZURE_STORAGE_ACCOUNT'] if @storage_acct_name == UNSET_VALUE
        @storage_access_key = ENV['AZURE_STORAGE_ACCESS_KEY'] if @storage_access_key == UNSET_VALUE
        @mgmt_certificate = ENV['AZURE_MANAGEMENT_CERTIFICATE'] if @mgmt_certificate == UNSET_VALUE
        @mgmt_endpoint = ENV['AZURE_MANAGEMENT_ENDPOINT'] if @mgmt_endpoint == UNSET_VALUE
        @subscription_id = ENV['AZURE_SUBSCRIPTION_ID'] if @subscription_id == UNSET_VALUE

        @vm_name = nil if @vm_name == UNSET_VALUE
        @vm_user = 'vagrant' if @vm_user == UNSET_VALUE
        @vm_password = nil if @vm_password == UNSET_VALUE
        @vm_image = nil if @vm_image == UNSET_VALUE
        @vm_location = 'West US' if @vm_location == UNSET_VALUE
        @vm_affinity_group = nil if @vm_affinity_group == UNSET_VALUE
        @vm_virtual_network_name = nil if @vm_virtual_network_name == UNSET_VALUE

        @cloud_service_name = nil if @cloud_service_name == UNSET_VALUE
        @deployment_name = nil if @deployment_name == UNSET_VALUE
        @tcp_endpoints = nil if @tcp_endpoints == UNSET_VALUE
        @private_key_file = nil if @private_key_file == UNSET_VALUE

        @ssh_port = nil if @ssh_port == UNSET_VALUE
        @vm_size = nil if @vm_size == UNSET_VALUE
        @winrm_transport = nil if @winrm_transport == UNSET_VALUE
        @winrm_http_port = nil if @winrm_http_port == UNSET_VALUE
        @winrm_https_port = nil if @winrm_https_port == UNSET_VALUE
        @availability_set_name = nil if @availability_set_name == UNSET_VALUE

        @state_read_timeout = nil if @state_read_timeout == UNSET_VALUE

        utils = Class.new.extend(Azure::Core::Utility)

        # This done due to a bug in Ruby SDK - it doesn't generate a storage
        # account name if add_role = true
        if @storage_acct_name.nil? || @storage_acct_name.empty?
          @storage_acct_name = utils.random_string("#{@vm_name}storage").gsub(/[^0-9a-z ]/i, '').downcase[0..23]
        end

        if @cloud_service_name.nil? || @cloud_service_name.empty?
          @cloud_service_name = utils.random_string("#{@vm_name}-service-")
        end
      end

      def validate(machine)
        errors = _detected_errors

        # Azure connection properties related validation.
        errors << 'vagrant_azure.subscription_id.required' if @subscription_id.nil?
        errors << 'vagrant_azure.mgmt_certificate.required' if @mgmt_certificate.nil?
        errors << 'vagrant_azure.mgmt_endpoint.required' if @mgmt_endpoint.nil?

        # Azure Virtual Machine related validation
        errors << 'vagrant_azure.vm_name.required' if @vm_name.nil?

        paths = machine.config.ssh.private_key_path
        unless @vm_password || machine.config.ssh.password || @private_key_file || (paths && paths.count > 0)
          errors << 'You must provide one of the following: ssh.private_key_path, azure.private_key_file, ssh.password or azure.vm_password.'
        end

        if (@private_key_file || (paths && paths.count > 0)) && (@vm_password || machine.config.ssh.password)
          machine.config.ssh.password = @vm_password = nil
          machine.ui.warn('You specified both private_key and password. Vagrant-Azure will only use the private_key in this case.')
        end

        if machine.config.ssh.password.nil? && @vm_password
          machine.config.ssh.password = @vm_password
        elsif machine.config.ssh.password && @vm_password.nil?
          @vm_password = machine.config.ssh.password
        end

        if machine.config.ssh.private_key_path.nil? && @private_key_file
          machine.config.ssh.private_key_path = [File.expand_path(@private_key_file)]
        elsif machine.config.ssh.private_key_path && @private_key_file.nil?
          @private_key_file = File.expand_path(paths.first)
        end

        { 'Microsoft Azure Provider' => errors }
      end
    end
  end
end

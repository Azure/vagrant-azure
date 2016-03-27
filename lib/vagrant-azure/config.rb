# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License in the project root for license information.
require 'vagrant'
require 'haikunator'

module VagrantPlugins
  module Azure
    class Config < Vagrant.plugin('2', :config)

      # The Azure Active Directory Tenant ID -- ENV['AZURE_TENANT_ID']
      #
      # @return [String]
      attr_accessor :tenant_id

      # The Azure Active Directory Application Client ID -- ENV['AZURE_CLIENT_ID']
      #
      # @return [String]
      attr_accessor :client_id

      # The Azure Active Directory Application Client Secret -- ENV['AZURE_CLIENT_SECRET']
      #
      # @return [String]
      attr_accessor :client_secret

      # The Azure Subscription ID to use -- ENV['AZURE_SUBSCRIPTION_ID']
      #
      # @return [String]
      attr_accessor :subscription_id

      # (Optional) Name of the resource group to use. WARNING: the resource group will be removed upon destroy!!!
      #
      # @return [String]
      attr_accessor :resource_group_name

      # (Optional) Azure location to build the VM -- defaults to 'westus'
      #
      # @return [String]
      attr_accessor :location

      # (Optional) Name of the storage account to use -- ENV['AZURE_STORAGE_ACCOUNT']
      #
      # @return [String]
      attr_accessor :storage_acct_name

      # (Optional) Name of the virtual machine
      #
      # @return [String]
      attr_accessor :vm_name

      # (Optional) Password for the VM
      #
      # @return [String]
      attr_accessor :vm_password

      # (Optional) VM size to be used -- defaults to 'Standard_D1'. See: https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-sizes/
      #
      # @return [String]
      attr_accessor :vm_size

      # (Optional) Name of the virtual machine image urn to use -- defaults to 'canonical:ubuntuserver:16.04.0-DAILY-LTS:latest'. See: https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-cli-ps-findimage/
      #
      # @return [String]
      attr_accessor :vm_image_urn

      # (Optional) Name of the virtual network resource
      #
      # @return [String]
      attr_accessor :virtual_network_name

      # (Optional) Name of the virtual network subnet resource
      #
      # @return [String]
      attr_accessor :subnet_name

      # (Optional) TCP endpoints to open up for the VM
      #
      # @return [String]
      attr_accessor :tcp_endpoints

      # (Optional) Name of the virtual machine image
      #
      # @return [String]
      attr_accessor :availability_set_name

      # (Optional) The timeout to wait for an instance to become ready -- default 120 seconds.
      #
      # @return [Fixnum]
      attr_accessor :instance_ready_timeout

      # (Optional) The interval to wait for checking an instance's state -- default 2 seconds.
      #
      # @return [Fixnum]
      attr_accessor :instance_check_interval

      # (Optional) The Azure Management API endpoint -- default 'https://management.azure.com' seconds -- ENV['AZURE_MANAGEMENT_ENDPOINT'].
      #
      # @return [String]
      attr_accessor :management_endpoint

      def initialize
        @tenant_id = UNSET_VALUE
        @client_id = UNSET_VALUE
        @client_secret = UNSET_VALUE
        @management_endpoint = UNSET_VALUE
        @subscription_id = UNSET_VALUE
        @resource_group_name = UNSET_VALUE
        @location = UNSET_VALUE
        @storage_acct_name = UNSET_VALUE
        @vm_name = UNSET_VALUE
        @vm_password = UNSET_VALUE
        @vm_image_urn = UNSET_VALUE
        @virtual_network_name = UNSET_VALUE
        @subnet_name = UNSET_VALUE
        @tcp_endpoints = UNSET_VALUE
        @vm_size = UNSET_VALUE
        @availability_set_name = UNSET_VALUE
        @instance_ready_timeout = UNSET_VALUE
        @instance_check_interval = UNSET_VALUE
      end

      def finalize!
        @storage_acct_name = ENV['AZURE_STORAGE_ACCOUNT'] if @storage_acct_name == UNSET_VALUE
        @management_endpoint = (ENV['AZURE_MANAGEMENT_ENDPOINT'] || 'https://management.azure.com') if @management_endpoint == UNSET_VALUE
        @subscription_id = ENV['AZURE_SUBSCRIPTION_ID'] if @subscription_id == UNSET_VALUE
        @tenant_id = ENV['AZURE_TENANT_ID'] if @tenant_id == UNSET_VALUE
        @client_id = ENV['AZURE_CLIENT_ID'] if @client_id == UNSET_VALUE
        @client_secret = ENV['AZURE_CLIENT_SECRET'] if @client_secret == UNSET_VALUE

        @vm_name = Haikunator.haikunate(100) if @vm_name == UNSET_VALUE
        @resource_group_name = Haikunator.haikunate(100) if @resource_group_name == UNSET_VALUE
        @vm_password = nil if @vm_password == UNSET_VALUE
        @vm_image_urn = 'canonical:ubuntuserver:16.04.0-DAILY-LTS:latest' if @vm_image_urn == UNSET_VALUE
        @location = 'westus' if @location == UNSET_VALUE
        @virtual_network_name = nil if @virtual_network_name == UNSET_VALUE
        @subnet_name = nil if @subnet_name == UNSET_VALUE
        @tcp_endpoints = nil if @tcp_endpoints == UNSET_VALUE
        @vm_size = 'Standard_D1' if @vm_size == UNSET_VALUE
        @availability_set_name = nil if @availability_set_name == UNSET_VALUE

        @instance_ready_timeout = 120 if @instance_ready_timeout == UNSET_VALUE
        @instance_check_interval = 2 if @instance_check_interval == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        # Azure connection properties related validation.
        errors << 'vagrant_azure.subscription_id.required' if @subscription_id.nil?
        errors << 'vagrant_azure.mgmt_endpoint.required' if @management_endpoint.nil?
        errors << 'vagrant_azure.auth.required' if @tenant_id.nil? || @client_secret.nil? || @client_id.nil?

        { 'Microsoft Azure Provider' => errors }
      end
    end
  end
end

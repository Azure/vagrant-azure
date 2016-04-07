# Vagrant Azure Provider

[![Gem Version](https://badge.fury.io/rb/vagrant-azure.png)](https://rubygems.org/gems/vagrant-azure)

This is a [Vagrant](http://www.vagrantup.com) 1.7.3+ plugin that adds [Microsoft Azure](https://azure.microsoft.com)
provider to Vagrant, allowing Vagrant to control and provision machines in Microsoft Azure.

## Usage

Install Vagrant 1.7.3 or higher - [Download Vagrant](http://www.vagrantup.com/downloads.html)

Install the vagrant-azure plugin using the standard Vagrant 1.1+ installation methods. After installing the plugin, you can ```vagrant up``` and use ```azure``` provider. For example:

```
C:\> vagrant plugin install vagrant-azure 2.0.0.pre1
...
C:\> vagrant up --provider=azure
...
```

You'll need an ```azure``` box before you can do ```vagrant up``` though.

## Quick Start

You can use the dummy box and specify all the required details manually in the ```config.vm.provider``` block in your ```Vagrantfile```. Add the dummy box with the name you want:

```
C:\> vagrant box add azure https://github.com/azure/vagrant-azure/raw/v2.0/dummy.box
...
```

Now edit your ```Vagrantfile``` as shown below and provide all the values as explained.

```ruby
Vagrant.configure('2') do |config|
  config.vm.box = 'azure'

  # use local ssh key to connect to remote vagrant box
  config.ssh.private_key_path = '~/.ssh/id_rsa'
  config.vm.provider :azure do |azure, override|

    # use Azure Active Directory Application / Service Principal to connect to Azure
    # see: https://azure.microsoft.com/en-us/documentation/articles/resource-group-create-service-principal-portal/

    # each of the below values will default to use the env vars named as below if not specified explicitly
    azure.tenant_id = ENV['AZURE_TENANT_ID']
    azure.client_id = ENV['AZURE_CLIENT_ID']
    azure.client_secret = ENV['AZURE_CLIENT_SECRET']
    azure.subscription_id = ENV['AZURE_SUBSCRIPTION_ID']
  end

end
```

Now you can run

```
C:\> vagrant up --provider=azure
```

This will bring up an Azure VM as per the configuration options set above.

You can now either SSH (if its a *Nix VM) using ```vagrant ssh```, RDP (if its a Windows VM) using ```vagrant rdp``` or PowerShell ```vagrant powershell```.

Normally, a lot of this options, e.g., ```vm_image_urn```, will be embedded in a box file and you just have to provide minimal options in the ```Vagrantfile```. Since, we're using a dummy box, there are no pre-configured defaults.

## Azure Boxes

The vagrant-azure plugin provides the ability to use ```Azure``` boxes with Vagrant. Please see the example box provided in [example_box/ directory](https://github.com/azure/vagrant-azure/tree/v2.0/example_box) and follow the instructions there to build an ```azure``` box.

Please see [Vagrant Docs](http://docs.vagrantup.com/v2/) for more details.

## Configuration

The vagrant-azure provide exposes a few Azure specific configuration options:

### Mandatory

For instructions on how to setup an Azure Active Directory Application see: https://azure.microsoft.com/en-us/documentation/articles/resource-group-create-service-principal-portal/
* `tenant_id`: Your Azure Active Directory Tenant Id.
* `client_id`: Your Azure Active Directory application client id.
* `client_secret`: Your Azure Active Directory application client secret.
* `subscription_id`: The Azure subscription Id you'd like to use.

### Optional
* `resource_group_name`: (Optional) Name of the resource group to use.
* `location`: (Optional) Azure location to build the VM -- defaults to 'westus'
* `vm_name`: (Optional) Name of the virtual machine
* `vm_password`: (Optional for *nix) Password for the VM -- This is not recommended for *nix deployments
* `vm_size`: (Optional) VM size to be used -- defaults to 'Standard_D1'. See: https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-sizes/
* `vm_image_urn`: (Optional) Name of the virtual machine image urn to use -- defaults to 'canonical:ubuntuserver:16.04.0-DAILY-LTS:latest'. See: https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-cli-ps-findimage/
* `virtual_network_name`: (Optional) Name of the virtual network resource
* `subnet_name`: (Optional) Name of the virtual network subnet resource
* `instance_ready_timeout`: (Optional) The timeout to wait for an instance to become ready -- default 120 seconds.
* `instance_check_interval`: (Optional) The interval to wait for checking an instance's state -- default 2 seconds.
* `endpoint`: (Optional) The Azure Management API endpoint -- default 'https://management.azure.com' seconds -- ENV['AZURE_MANAGEMENT_ENDPOINT'].

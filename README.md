# Vagrant Azure Provider

[![Gem Version](https://badge.fury.io/rb/vagrant-azure.png)](https://rubygems.org/gems/vagrant-azure)

This is a [Vagrant](http://www.vagrantup.com) 1.7.3+ plugin that adds [Microsoft Azure](https://azure.microsoft.com)
provider to Vagrant, allowing Vagrant to control and provision machines in Microsoft Azure.

## Usage

[Download Vagrant](http://www.vagrantup.com/downloads.html)

Install the vagrant-azure plugin using the standard Vagrant 1.1+ installation methods. After installing the plugin, you can ```vagrant up``` and use ```azure``` provider. For example:

```sh
& vagrant plugin install vagrant-azure --plugin-version '2.0.0.pre2'
...
$ vagrant up --provider=azure
...
```

You'll need an ```azure``` box before you can do ```vagrant up``` though.

## Quick Start

You can use the dummy box and specify all the required details manually in the ```config.vm.provider``` block in your ```Vagrantfile```. Add the dummy box with the name you want:

```sh
$ vagrant box add azure https://github.com/azure/vagrant-azure/raw/v2.0/dummy.box
...
```

For ***nix**, edit your `Vagrantfile` as shown below and provide all the values as explained.

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

For **Windows**, edit your `Vagrantfile` as shown below and provide all the values as explained.

```ruby
Vagrant.configure('2') do |config|
  config.vm.box = 'azure'

  config.vm.provider :azure do |azure, override|

    # use Azure Active Directory Application / Service Principal to connect to Azure
    # see: https://azure.microsoft.com/en-us/documentation/articles/resource-group-create-service-principal-portal/

    # each of the below values will default to use the env vars named as below if not specified explicitly
    azure.tenant_id = ENV['AZURE_TENANT_ID']
    azure.client_id = ENV['AZURE_CLIENT_ID']
    azure.client_secret = ENV['AZURE_CLIENT_SECRET']
    azure.subscription_id = ENV['AZURE_SUBSCRIPTION_ID']

    azure.vm_image_urn = 'MicrosoftSQLServer:SQL2016-WS2012R2:Express:latest'
    azure.instance_ready_timeout = 600
    azure.vm_password = 'TopSecretPassw0rd'
    azure.admin_username = "OctoAdmin"
    azure.admin_password = 'TopSecretPassw0rd'
    override.winrm.transport = :ssl
    override.winrm.port = 5986
    override.winrm.ssl_peer_verification = false # must be false if using a self signed cert
  end

end
```

Now you can run

```sh
$ vagrant up --provider=azure
...
```

This will bring up an Azure VM as per the configuration options set above.

You can now either SSH (if its a *Nix VM) using ```vagrant ssh```, RDP (if its a Windows VM) using ```vagrant rdp``` or PowerShell ```vagrant powershell```.

Normally, a lot of this options, e.g., ```vm_image_urn```, will be embedded in a box file and you just have to provide minimal options in the ```Vagrantfile```. Since, we're using a dummy box, there are no pre-configured defaults.

## Azure Boxes

The vagrant-azure plugin provides the ability to use ```Azure``` boxes with Vagrant. Please see the example box provided in [example_box](https://github.com/azure/vagrant-azure/tree/v2.0/example_box) directory and follow the instructions there to build an ```azure``` box.

Please see [Vagrant Docs](http://docs.vagrantup.com/v2/) for more details.

## Configuration

The vagrant-azure provide exposes a few Azure specific configuration options:

### Mandatory

For instructions on how to setup an Azure Active Directory Application see: <https://azure.microsoft.com/en-us/documentation/articles/resource-group-create-service-principal-portal/>

* `tenant_id`: Your Azure Active Directory Tenant Id.
* `client_id`: Your Azure Active Directory application client id.
* `client_secret`: Your Azure Active Directory application client secret.
* `subscription_id`: The Azure subscription Id you'd like to use.

### Optional

* `resource_group_name`: (Optional) Name of the resource group to use.
* `location`: (Optional) Azure location to build the VM -- defaults to `westus`
* `vm_name`: (Optional) Name of the virtual machine
* `vm_password`: (Optional for *nix) Password for the VM -- This is not recommended for *nix deployments
* `vm_size`: (Optional) VM size to be used -- defaults to 'Standard_DS2_v2'. See sizes for [*nix](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-sizes/), [Windows](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-sizes/).
* `vm_image_urn`: (Optional) Name of the virtual machine image urn to use -- defaults to 'canonical:ubuntuserver:16.04-LTS:latest'. See documentation for [*nix](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-cli-ps-findimage/), [Windows](https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-windows-cli-ps-findimage).
* `virtual_network_name`: (Optional) Name of the virtual network resource
* `subnet_name`: (Optional) Name of the virtual network subnet resource
* `instance_ready_timeout`: (Optional) The timeout to wait for an instance to become ready -- default 120 seconds.
* `instance_check_interval`: (Optional) The interval to wait for checking an instance's state -- default 2 seconds.
* `endpoint`: (Optional) The Azure Management API endpoint -- default `ENV['AZURE_MANAGEMENT_ENDPOINT']` if exists, falls back to <https://management.azure.com>.
* `admin_username`: (Optional) The root/administrator username for the VM
* `admin_password`: (Optional, Windows only) The password to set for the windows administrator user
* `winrm_install_self_signed_cert`: (Optional, Windows only) Whether to install a self-signed cert automatically to enable WinRM to communicate over HTTPS (5986). Only available when a custom `deployment_template` is not supplied. Default 'true'.
* `deployment_template`: (Optional) A custom ARM template to use instead of the default template

# Vagrant Azure Provider

[![Gem Version](https://badge.fury.io/rb/vagrant-azure.png)](https://rubygems.org/gems/vagrant-azure)

This is a [Vagrant](http://www.vagrantup.com) 1.7.3+ plugin that adds [Microsoft Azure](https://azure.microsoft.com)
provider to Vagrant, allowing Vagrant to control and provision machines in Microsoft Azure.

## Usage

[Download Vagrant](http://www.vagrantup.com/downloads.html)

Install the vagrant-azure plugin using the standard Vagrant 1.1+ installation methods. After installing the plugin, you can ```vagrant up``` and use ```azure``` provider. For example:

```sh
& vagrant plugin install vagrant-azure --plugin-version '2.0.0.pre6'
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

### Create an Azure Active Directory (AAD) Application
AAD encourages the use of Applications / Service Principals for authenticating applications. An 
application / service principal combination provides a service identity for Vagrant to manage your Azure Subscription.
[Click here to learn about AAD applications and service principals.](https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-application-objects.)
- [Install the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- run `az login` to log into Azure
- run `az ad sp create-for-rbac` to create an Azure Active Directory Application with access to Azure Resource Manager for the current Azure Subscription
  - If you want to run this for a different Azure Subscription, run `az account set --subscription 'your subscription name'`
- run `az account list --query "[?isDefault].id" -o tsv` to get your Azure Subscription Id.
  
The output of `az ad sp create-for-rbac` should look like the following:
```json
{
  "appId": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
  "displayName": "some-display-name",
  "name": "http://azure-cli-2017-04-03-15-30-52",
  "password": "XXXXXXXXXXXXXXXXXXXX",
  "tenant": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
}
```
The values `tenant`, `appId` and `password` map to the configuration values 
`azure.tenant_id`, `azure.client_id` and `azure.client_secret` in your Vagrant file or environment variables.

For ***nix**, edit your `Vagrantfile` as shown below and provide all the values as explained.

```ruby
Vagrant.configure('2') do |config|
  config.vm.box = 'azure'

  # use local ssh key to connect to remote vagrant box
  config.ssh.private_key_path = '~/.ssh/id_rsa'
  config.vm.provider :azure do |azure, override|

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

    # each of the below values will default to use the env vars named as below if not specified explicitly
    azure.tenant_id = ENV['AZURE_TENANT_ID']
    azure.client_id = ENV['AZURE_CLIENT_ID']
    azure.client_secret = ENV['AZURE_CLIENT_SECRET']
    azure.subscription_id = ENV['AZURE_SUBSCRIPTION_ID']

    azure.vm_image_urn = 'MicrosoftSQLServer:SQL2016-WS2012R2:Express:latest'
    azure.instance_ready_timeout = 600
    azure.vm_password = 'TopSecretPassw0rd'
    azure.admin_username = "OctoAdmin"
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

The vagrant-azure provide exposes Azure specific configuration options:

### Mandatory
* `tenant_id`: Your Azure Active Directory Tenant Id.
* `client_id`: Your Azure Active Directory application client id.
* `client_secret`: Your Azure Active Directory application client secret.
* `subscription_id`: The Azure subscription Id you'd like to use.
*Note: to procure these values see: [Create an Azure Active Directory Application](#create-an-azure-active-directory-aad-application)*

### Optional Image Parameters
* `vm_image_urn`: (Optional) Name of the virtual machine image urn to use -- defaults to 'canonical:ubuntuserver:16.04-LTS:latest'. See documentation for [*nix](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-cli-ps-findimage/), [Windows](https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-windows-cli-ps-findimage).
* `vm_custom_image`: (Optional) URI to the custom VHD. If the VHD is not publicly accessible, provide a SAS token in the URI.
    * `vm_operating_system`: (Mandatory) Must provide the OS if using a custom image ("Linux" or "Windows")

### Optional Data Disk Parameters
* `data_disks`: (Optional) Array of Data Disks to attach to the VM. For information on attaching the drive, see: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/classic/attach-disk.
```ruby
override.data_disks = [
    # sample of creating empty data disk
    {
      name: "mydatadisk1", 
      size_gb: 30
    }, 
    # sample of attaching an existing VHD as a data disk
    {
      name: "mydatadisk2", 
      vhd_uri: "http://mystorage.blob.core.windows.net/vhds/mydatadisk2.vhd"
    },
    # sample of attaching a data disk from image
    {
      name: "mydatadisk3", 
      vhd_uri: "http://mystorage.blob.core.windows.net/vhds/mydatadisk3.vhd", 
      image: "http: //storagename.blob.core.windows.net/vhds/VMImageName-datadisk.vhd"
    }]
```

### Optional

* `resource_group_name`: (Optional) Name of the resource group to use.
* `location`: (Optional) Azure location to build the VM -- defaults to `westus`
* `vm_name`: (Optional) Name of the virtual machine
* `vm_password`: (Optional for *nix) Password for the VM -- This is not recommended for *nix deployments
* `vm_size`: (Optional) VM size to be used -- defaults to 'Standard_DS2_v2'. See sizes for [*nix](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-sizes/), [Windows](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-sizes/).
* `virtual_network_name`: (Optional) Name of the virtual network resource
* `dns_name`: (Optional) DNS Label Prefix 
* `nsg_name`: (Optional) Network Security Group Label Prefix 
* `subnet_name`: (Optional) Name of the virtual network subnet resource
* `tcp_endpoints`: (Optional) The custom inbound security rules part of network security group (a.k.a. opened tcp endpoints). Allows specifying one or more intervals in the form of:
  * an array `['8000-9000', '9100-9200']`, 
  * a single interval as `'8000-9000'`,
  * a single port as `8000`.
* `instance_ready_timeout`: (Optional) The timeout to wait for an instance to become ready -- default 120 seconds.
* `instance_check_interval`: (Optional) The interval to wait for checking an instance's state -- default 2 seconds.
* `endpoint`: (Optional) The Azure Management API endpoint -- default `ENV['AZURE_MANAGEMENT_ENDPOINT']` if exists, falls back to <https://management.azure.com>.
* `admin_username`: (Optional) The root/administrator username for the VM
* `winrm_install_self_signed_cert`: (Optional, Windows only) Whether to install a self-signed cert automatically to enable WinRM to communicate over HTTPS (5986). Only available when a custom `deployment_template` is not supplied. Default 'true'.
* `wait_for_destroy`: (Optional) Wait for all resources to be deleted prior to completing Vagrant destroy -- default false.

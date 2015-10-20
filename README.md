# Vagrant Azure Provider

[![Gem Version](https://badge.fury.io/rb/vagrant-azure.png)](https://rubygems.org/gems/vagrant-azure)

This is a [Vagrant](http://www.vagrantup.com) 1.7.3+ plugin that adds [Microsoft Azure](https://azure.microsoft.com)
provider to Vagrant, allowing Vagrant to control and provision machines in Microsoft Azure.

## Usage

Install Vagrant 1.7.3 or higher - [Download Vagrant](http://www.vagrantup.com/downloads.html)

Install the vagrant-azure plugin using the standard Vagrant 1.1+ installation methods. After installing the plugin, you can ```vagrant up``` and use ```azure``` provider. For example:

```
C:\> vagrant plugin install vagrant-azure
...
C:\> vagrant up --provider=azure
...
```

You'll need an ```azure``` box before you can do ```vagrant up``` though.

## Quick Start

You can use the dummy box and specify all the required details manually in the ```config.vm.provider``` block in your ```Vagrantfile```. Add the dummy box with the name you want:

```
C:\> vagrant box add azure https://github.com/msopentech/vagrant-azure/raw/master/dummy.box
...
```

Now edit your ```Vagrantfile``` as shown below and provide all the values as explained.

```ruby
Vagrant.configure('2') do |config|
	config.vm.box = 'azure'
	
	config.vm.provider :azure do |azure, override|
		# Mandatory Settings 
		azure.mgmt_certificate = 'YOUR AZURE MANAGEMENT CERTIFICATE'
		azure.mgmt_endpoint = 'https://management.core.windows.net'
		azure.subscription_id = 'YOUR AZURE SUBSCRIPTION ID'
		azure.vm_image = 'NAME OF THE IMAGE TO USE'
		azure.vm_name = 'PROVIDE A NAME FOR YOUR VIRTUAL MACHINE' # max 15 characters. contains letters, number and hyphens. Can start with letters and can end with letters and numbers. May NOT contain underscores "_"
		
		# vm_password is optional when specifying the private_key_file with Linux VMs
		# When building a Windows VM and using WinRM this setting is used to authenticate via WinRM (PowerShell Remoting)
		azure.vm_password = 'PROVIDE A VALID PASSWORD' # min 8 characters. should contain a lower case letter, an uppercase letter, a number and a special character
		
		# Optional Settings
		azure.storage_acct_name = 'NAME OF YOUR STORAGE ACCOUNT' # optional. A new one will be generated if not provided.
		azure.vm_user = 'PROVIDE A USERNAME' # defaults to 'vagrant' if not provided
		azure.cloud_service_name = 'PROVIDE A NAME FOR YOUR CLOUD SERVICE' # same as vm_name. leave blank to auto-generate
		azure.deployment_name = 'PROVIDE A NAME FOR YOUR DEPLOYMENT' # defaults to cloud_service_name
	    azure.vm_location = 'PROVIDE A LOCATION FOR VM' # e.g., West US
		
		# Optional *Nix Settings
		azure.ssh_port = 'A VALID PUBLIC PORT' # defaults to 22
		azure.private_key_file = 'Path to your ssh private key file (~/.ssh/id_rsa) to use for passwordless auth. If the id_rsa file is password protected, you will be prompted for the password.'
	
		# Optional Windows Settings
		azure.winrm_transport = [ 'http', 'https' ] # this will open up winrm ports on both http (5985) and http (5986) ports
		azure.winrm_https_port = 'A VALID PUBLIC PORT' # customize the winrm https port, instead of 5986
		azure.winrm_http_port = 'A VALID PUBLIC PORT' # customize the winrm http port, insted of 5985
		azure.tcp_endpoints = '3389:53389' # opens the Remote Desktop internal port that listens on public port 53389. Without this, you cannot RDP to a Windows VM.
	end
end
```

Now you can run

```
C:\> vagrant up --provider=azure
```

This will bring up an Azure VM as per the configuration options set above.

You can now either SSH (if its a *Nix VM) using ```vagrant ssh```, RDP (if its a Windows VM) using ```vagrant rdp``` or PowerShell ```vagrant powershell```.

Normally, a lot of this options, e.g., ```vm_image```, will be embedded in a box file and you just have to provide minimal options in the ```Vagrantfile```. Since, we're using a dummy box, there are no pre-configured defaults.

## Azure Boxes

The vagrant-azure plugin provides the ability to use ```Azure``` boxes with Vagrant. Please see the example box provided in [example_box/ directory](https://github.com/msopentech/vagrant-azure/tree/master/example_box) and follow the instructions there to build an ```azure``` box.

Please see [Vagrant Docs](http://docs.vagrantup.com/v2/) for more details.

## Configuration

The vagrant-azure provide exposes a few Azure specific configuration options:

### Mandatory

* `mgmt_certificate` - Your Azure Management certificate which has been uploaded to the Azure portal for your account. Provide [PEM file path](#pem-generation), PFX file path or raw string.
* `mgmt_endpoint` - Azure Management endpoint. `https://management.core.windows.net`
* `subscription_id` - Your Azure Subscription ID.
* `storage_acct_name` - The Storage account to use when creating VMs.
* `vm_name` - The name of the created VM.

### Optional

* `vm_user` - The username to create the VM with. Defaults to `vagrant`.
* `vm_password` - The password to set for the user created with the VM. This will override the private_key_file setting.
* `vm_image` - The name of the image to be used when creating the VM.
* `vm_size` - The size of the created VM. Use an of the Azure VM Sizes.
* `vm_virtual_network_name` - The name of a virtual network to connect to
* `cloud_service_name` - The name of the cloud service under which to create the VM.
* `deployment_name` - The name to give the deployment in the cloud service and add the VM to.
* `vm_location` - The location to create the cloud service, storage account.
* `private_key_file` - The private key file to use for SSH (~/.ssh/id_rsa) or a [PEM file](#pem-generation).
* `ssh_port` - To map the internal SSH port 22 to a different public port.
* `winrm_transport` - Enables or disables WinRm. Allowed values are `http` and `https`.
* `winrm_https_port` To map the internal WinRM https port 5986 to a different public port. Must be non-empty.
* `winrm_http_port` To map the internal WinRM http port 5985 to a different public port. Must be non-empty.
* `tcp_endpoints` - To open any additional ports. E.g., `80` opens port `80` and `80,3389:53389` opens port `80` and `3389`. Also maps the interal port `3389` to public port `53389`

### Certificate Generation on Windows
We will use `makecert.exe` distributed as part of the in the Windows 7 SDK.  The following commands will create the required certificate and insert it into the current user’s personal store.

```
makecert.exe -r -pe -a sha1 -n "CN=AzCert" -ss My -sr CurrentUser -len 2048 -sky exchange -sp "Microsoft Enhanced RSA and AES Cryptographic Provider" -sy 24
```

(In order to have more details with images in Windows)[http://blogs.msdn.com/b/cclayton/archive/2012/03/21/windows-azure-and-x509-certificates.aspx]

### Get Started with Publish Settings

To create a pfx from the publishsettings, simply download the publishsettings file for your subscription 
[https://manage.windowsazure.com/publishsettings](https://manage.windowsazure.com/publishsettings/index?client=powershell). Make sure you have the [Ruby Azure](https://rubygems.org/gems/azure/versions/0.7.0) gem installed and run `pfxer transform --in [path to your .publishsettings file]`. This will create a .pfx from your publish settings file which can be supplied as a cert parameter for Service Management Commands.

### Get Started with OpenSSL

* Using the following openssl commands to create a cert and upload to Azure Management
  * Generate public and private `openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout cert.pem -out cert.pem`
  * Generate public .cer for Azure upload `openssl x509 -inform pem -in cert.pem -outform der -out mgmt.cer`
  * Upload the `mgmt.cer` to Azure Management through [https://management.azure.com](https://management.azure.com)
  * Use cert.pem as your cert parameter for Service Management Commands.

### Using your .pem certificate

Vagrant-Azure expects you to use a .pem management certificate as shown below:

```ruby
Vagrant.configure('2') do |config|
	config.vm.box = 'azure'

	config.vm.provider :azure do |azure|
		azure.mgmt_certificate = "#{file_location_of_your_dot_pem}"
```

## Create Virtual Network

In order to use vagrant-azure's `vm_virtual_network_name` support, create virtual networks using
[Azure's Command Line Interface](http://azure.microsoft.com/en-us/documentation/articles/virtual-machines-command-line-tools/):

    azure account download
    azure network vnet create --vnet "vnet-name" --location "West US" --create-new-affinity-group


## New Commands for `azure` provider

The `azure` provider introduces the following new `vagrant` commands.

* `rdp` - To connect to a Windows VM using RDP. E.g.,
* `powershell` - To execute remote powershell commands on a Windows VM using WinRM. 
```
> vagrant up --provider=azure
...
> vagrant rdp
...
> vagrant powershell
```


## Multi Machine
The options for multi machines are similar to Vagrant, please refer to the vagrant doc at http://docs.vagrantup.com/v2/multi-machine/index.html

Example Multi Machine Vagrantfile (for building out 3 Windows Virtual Machines)

```ruby

Vagrant.configure('2') do |config|
  config.vm.boot_timeout = 1000

  do_common_azure_stuff = Proc.new do |azure, override|
		override.config.vm.box = 'azure'

		azure.mgmt_certificate = 'YOUR AZURE MANAGEMENT CERTIFICATE'
		azure.mgmt_endpoint = 'https://management.core.windows.net'
		azure.subscription_id = 'YOUR AZURE SUBSCRIPTION ID'
		azure.storage_acct_name = 'NAME OF YOUR STORAGE ACCOUNT' # optional. A new one will be generated if not provided.

		azure.vm_image = 'NAME OF THE IMAGE TO USE'
		azure.vm_user = 'PROVIDE A USERNAME' # defaults to 'vagrant' if not provided
		azure.vm_password = 'PROVIDE A VALID PASSWORD' # min 8 characters. should contain a lower case letter, an uppercase letter, a number and a special character

		azure.vm_name = 'PROVIDE A NAME FOR YOUR VIRTUAL MACHINE' # max 15 characters. contains letters, number and hyphens. can start with letters and can end with letters and numbers
		azure.cloud_service_name = 'PROVIDE A NAME FOR YOUR CLOUD SERVICE' # same as vm_name. leave blank to auto-generate
		azure.deployment_name = 'PROVIDE A NAME FOR YOUR DEPLOYMENT' # defaults to cloud_service_name
		azure.vm_location = 'PROVIDE A LOCATION FOR VM' # e.g., West US

		azure.winrm_transport = %w(https)
  end

  config.vm.define 'first' do |cfg|
    cfg.vm.provider :azure do |azure, override|
      do_common_azure_stuff.call azure, override
      azure.vm_name = 'PROVIDE A NAME FOR YOUR VIRTUAL MACHINE'
      azure.tcp_endpoints = '3389:53389' # opens the Remote Desktop internal port that listens on public port 53389. Without this, you cannot RDP to a Windows VM.
      azure.winrm_https_port = 5986
    end
  end

  config.vm.define 'second' do |cfg|
    cfg.vm.provider :azure do |azure, override|
      do_common_azure_stuff.call azure, override
      azure.vm_name = 'PROVIDE A NAME FOR YOUR VIRTUAL MACHINE'
      azure.tcp_endpoints = '3389:53390'
      azure.winrm_https_port = 5987
    end
  end

  config.vm.define 'third' do |cfg|
    cfg.vm.provider :azure do |azure, override|
      do_common_azure_stuff.call azure, override
      azure.vm_name = 'PROVIDE A NAME FOR YOUR VIRTUAL MACHINE'
      azure.tcp_endpoints = '3389:53391'
      azure.winrm_https_port = 5988
    end
  end

  # Executes powershell on the remote machine and returns the hostname
  config.vm.provision 'shell', inline: 'hostname'

end

```


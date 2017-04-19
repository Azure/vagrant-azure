# Ubuntu Xenial Machine from VHD
This scenario will build a custom image from a prepared Ubuntu Xenial VHD. This will build an Azure Managed
Image from the custom generalized VHD. The Azure Managed Image will be used to create a new Azure Virtual
Machine.

To see more information about this scenario, see [Prepare an Ubuntu virtual machine for Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/create-upload-ubuntu)

Before you attempt this scenario, ensure you have followed the [getting started docs](../../readme.md#getting-started).

If you wanted to build a more customized image, you could do the same with your own VHD manually by following these 
[instructions](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/create-upload-ubuntu?toc=%2fazure%2fvirtual-machines%2flinux%2ftoc.json#manual-steps).

## Vagrant up
We will set this up with Azure CLI and then run Vagrant after we've provisioned the needed Azure resources.
- Login to Azure CLI (if not already logged in)
  ```sh
  az login
  ```
- Create a resource group for your VHDs (assuming westus)
  ```sh
  az group create -n vagrantimages -l westus
  ```
- Create a storage account in the region you'd like to deploy
  ```sh
  # insert your own name for the storage account DNS name (-n)
  az storage account create -g vagrantimages -n vagrantimagesXXXX --sku Standard_LRS -l westus
  ```
- Download and unzip the VHD from Ubuntu
  ```sh
  wget -qO- -O tmp.zip http://cloud-images.ubuntu.com/releases/xenial/release/ubuntu-16.04-server-cloudimg-amd64-disk1.vhd.zip && unzip tmp.zip && rm tmp.zip
  ```
- Upload the VHD to your storage account in the vhds container
  ```sh
  conn_string=$(az storage account show-connection-string -g vagrantimages -n vagrantimagesXXXX -o tsv)
  az storage container create -n vhds --connection-string $conn_string
  az storage container create -n vhds vagrantimagesXXXX
  az storage blob upload -c vhds -n xenial-server-cloudimg-amd64-disk1.vhd -f xenial-server-cloudimg-amd64-disk1.vhd --connection-string $conn_string
  ```
- Update Vagrantfile with the URI of your uploaded blob (`azure.vm_vhd_uri`).
- Vagrant up
  ```bash
  vagrant up --provider=azure
  ```
  
To clean up, run `vagrant destroy`
  
 
 
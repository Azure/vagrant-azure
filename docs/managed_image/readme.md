# Ubuntu Machine from a Captured Managed Image
This scenario will build a machine from a captured managed image. We will build a VM with Azure CLI, capture 
an image of the VM and use that image reference for a new Vagrant machine.

To see more information about this scenario, see [Create a VM from the captured image](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/capture-image#step-3-create-a-vm-from-the-captured-image)

Before you attempt this scenario, ensure you have followed the [getting started docs](../../readme.md#getting-started).

## Vagrant up
We will set this up with Azure CLI and then run Vagrant after we've provisioned the needed Azure resources.
- Login to Azure CLI (if not already logged in)
  ```bash
  az login
  ```
- Create a resource group for your VHDs (assuming westus)
  ```bash
  az group create -n vagrant -l westus
  ```
- Create a new VM
  ```bash
  az vm create -g vagrant -n vagrant-box --admin-username deploy --image UbuntuLTS
  ```
- Capture an image of the VM
  ```bash
  az vm deallocate -g vagrant -n vagrant-box
  az vm generalize -g vagrant -n vagrant-box
  az image create -g vagrant --name vagrant-box-image --source vagrant-box
  ```
  You should see json output from the `az image create` command. Extract the "id" value from below for use in your Vagrantfile.
  ```json
    {
      "id": "/subscriptions/XXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXX/resourceGroups/vagrant/providers/Microsoft.Compute/images/vagrant-box-image",
      "location": "westus",
      "name": "vagrant-box-image",
      "provisioningState": "Succeeded",
      "resourceGroup": "vagrant",
      "sourceVirtualMachine": {
        "id": "/subscriptions/XXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXX/resourceGroups/vagrant-test/providers/Microsoft.Compute/virtualMachines/vagrant-box",
        "resourceGroup": "vagrant"
      },
      "storageProfile": {
        "dataDisks": [],
        "osDisk": {
          "blobUri": null,
          "caching": "ReadWrite",
          "diskSizeGb": null,
          "managedDisk": {
            "id": "/subscriptions/XXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXX/resourceGroups/vagrant-test/providers/Microsoft.Compute/disks/osdisk_5ZglGr7Rj4",
            "resourceGroup": "vagrant"
          },
          "osState": "Generalized",
          "osType": "Linux",
          "snapshot": null
        }
      },
      "tags": null,
      "type": "Microsoft.Compute/images"
    }
  ```
- Update the Vagrantfile in this directory with the URI of your managed image resource (`azure.vm_managed_image_id`).
- Vagrant up
  ```bash
  vagrant up --provider=azure
  ```
  
To clean up, run `vagrant destroy`
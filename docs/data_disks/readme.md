# Linux Machine with Empty Data Disks
This scenario will build an Ubuntu 16.04 machine with data disks attached to the virtual machine.

To see more information about this scenario, see [How to Attach a Data Disk to a Linux VM](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/classic/attach-disk)

Before you attempt this scenario, ensure you have followed the [getting started docs](../../readme.md#getting-started).

*Note: data disk support is preview and will likely change before becoming stable*

## Vagrant up
- In this directory, run the following
  ```bash
  vagrant up --provider=azure
  ```
- The Vagrant file specifies on data disk named foo. The foo disk is not formatted, nor mounted. If you
  would like to use the disk, you will need to format and mount the drive. For instructions on how to do that,
  see: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/classic/attach-disk#initialize-a-new-data-disk-in-linux.
  In the next rev of data disks, we'll handle mounting and formatting.
  
To clean up, run `vagrant destroy`
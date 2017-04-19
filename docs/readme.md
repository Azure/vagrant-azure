# Vagrant Azure Scenario Docs
Here you can find some common scenarios for using Azure plugin for Vagrant.

## Prerequisites
Before you attempt any scenario, ensure you have followed the [getting started docs](../readme.md#getting-started).

## Scenarios

### [Basic Linux Setup](./basic_linux)
Setup a simple Ubuntu 16.04 machine

### [Basic Windows Setup](./basic_windows)
Setup a Windows SQL Server 2016 machine

### [Ubuntu Xenial Machine from VHD](./custom_vhd)
Setup an Ubuntu box from a custom VHD

### [Managed Image Reference](./managed_image)
Setup a VM from a managed image reference captured from a previously created Azure VM.

### [Data Disks (empty disk)](./data_disks)
Setup an Ubuntu box with an empty attached disk

## Azure Boxes

The vagrant-azure plugin provides the ability to use ```Azure``` boxes with Vagrant. Please see the example box 
provided in [example_box](https://github.com/azure/vagrant-azure/tree/v2.0/example_box) directory and follow the 
instructions there to build an `azure` box.

For general Vagrant documentation see [Vagrant Docs](http://docs.vagrantup.com/v2/).
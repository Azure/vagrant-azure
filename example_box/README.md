# Vagrant Azure Example Box

This directory contains the sample contents of a box for `azure` provider. Build this into a box using:

On Windows:
```
C:\> bsdtar -cvzf azure.box metadata.json Vagrantfile
```

On *Nix:
```
$ tar cvzf azure.box ./metadata.json ./Vagrantfile
```

You can add any defaults supported by the ```azure``` provider to the `Vagrantfile` in your box and Vagrant's built-in merging system will set them as defaults. Users can override these defaults in their own Vagrantfiles.

You can specify the image to be used for the VM here via the ```vm_image``` option. E.g.,

```ruby
Vagrant.configure('2') do |config|
  config.vm.box = 'azure'

  config.vm.provider :azure do |azure|
    azure.vm_image = 'NAME OF THE IMAGE TO USE'
  end
end
```

See also: [`Get-AzureVMImage`](http://msdn.microsoft.com/en-us/library/azure/dn495275.aspx)

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

## 1.0.5 (Unreleased)

FEATURES

- Provision for windows VM.
- Windows VM has to be specifically mentioned in the  Vagrantfile with
  `config.vm.guest = :windows`
- Chef, Puppet and Shell provision for Linux and Windows VM.
- **SyncedFolders**
- Linux VM uses `rsync` and has be mentioned in the VagrantFile.
- Windows VM will default to use PowerShell to copy files.

IMPROVEMENTS

  - Better exception handling when VM fails to get created in cloud.
  - Better exception handling for WinRM session errors.

BUGFIXES

  - Cleaned up few typo in README
  - Compatible with Vagrant 1.6 [GH-15]

## Previous
See git commits

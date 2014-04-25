## 1.0.5 (Unreleased)

FEATURES

  - Provision for windows VM. Windows VM has to be specifically mentioned in the
    Vagrantfile with `config.vm.guest = :windows`
  - SyncedFolders for VM, `rsync` for Linux VM and `powershelll` file copy from Windows.
  - Chef, Puppet and Shell provision for Linux and Windows VM.

IMPROVEMENTS

  - Cleaned up few typo in README
  - Better exception handling when VM fails to get created in cloud.
  - Better exception handling for WinRM session errors.

# Previous
See git commits

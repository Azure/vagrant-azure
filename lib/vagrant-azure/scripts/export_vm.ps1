#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
#--------------------------------------------------------------------------

param (
    [string]$vm_id = $(throw "-vm_id is required."),
    [string]$path = $(throw "-path is required.")
)

# Include the following modules
$presentDir = Split-Path -parent $PSCommandPath
. ([System.IO.Path]::Combine($presentDir, "utils\write_messages.ps1"))


# Export the Virtual Machine
try {
  $vm = Get-Vm -Id $vm_id
  $vm  | Export-VM -Path $path -ErrorAction "stop"
  $name = $vm.name
  $resultHash = @{
    name = "$name"
  }
  Write-Output-Message $resultHash
  } catch {
    $errortHash = @{
      type = "PowerShellError"
      error = "Failed to export a  VM $_"
    }
    Write-Error-Message $errortHash
  }

#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
#--------------------------------------------------------------------------

param (
    [string]$vm_id = $(throw "-vm_id is required."),
    [string]$command = ""
 )

# Include the following modules
$presentDir = Split-Path -parent $PSCommandPath
. ([System.IO.Path]::Combine($presentDir, "utils\write_messages.ps1"))

try {
  $vm = Get-VM -Id $vm_id -ErrorAction "stop"
  switch ($command) {
    "start" { Start-VM $vm }
    "stop" { Stop-VM $vm }
    "suspend" { Suspend-VM $vm }
    "resume" { Resume-VM $vm }
  }

  $state = $vm.state
  $status = $vm.status
  $name = $vm.name
  } catch [Microsoft.HyperV.PowerShell.VirtualizationOperationFailedException] {
    $state = "not_created"
    $status = "Not Created"
  }
  $resultHash = @{
    state = "$state"
    status = "$status"
    name = "$name"
  }
  Write-Output-Message $resultHash

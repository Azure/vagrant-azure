#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#--------------------------------------------------------------------------

# Include the following modules
$presentDir = Split-Path -parent $PSCommandPath
. ([System.IO.Path]::Combine($presentDir, "utils\write_messages.ps1"))

try {
$hostname =  $(whoami)
$ip = (Get-WmiObject -class win32_NetworkAdapterConfiguration -Filter 'ipenabled = "true"').ipaddress[0]
  $resultHash = @{
    host_name = "$username"
    host_ip = "$ip"
  }
  Write-Output-Message $resultHash
}
catch {
  $errortHash = @{
    type = "PowerShellError"
    error = "$_"
  }
  Write-Error-Message $errortHash
}

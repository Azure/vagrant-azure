#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
#--------------------------------------------------------------------------

param (
    [string]$guest_ip = $(throw "-guest_ip is required."),
    [string]$guest_port = $(throw "-guest_port is required."),
    [string]$username = $(throw "-guest_username is required."),
    [string]$password = $(throw "-guest_password is required."),
    [string]$command = ""
)

# Include the following modules
$presentDir = Split-Path -parent $PSCommandPath
. ([System.IO.Path]::Combine($presentDir, "utils\write_messages.ps1"))
. ([System.IO.Path]::Combine($presentDir, "utils\create_session.ps1"))

try {
  $response = Create-Remote-Session $guest_ip $guest_port $username $password
  if (!$response["session"] -and $response["error"]) {
      Write-Host $response["error"]
      return
  }
  function Remote-Execute($command) {
    cmd /c $command
  }
  Invoke-Command -Session $response["session"] -ScriptBlock ${function:Remote-Execute} -ArgumentList $command -ErrorAction "stop"
} catch {
  Write-Host $_
  return
}

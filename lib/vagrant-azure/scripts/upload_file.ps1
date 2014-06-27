#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#--------------------------------------------------------------------------

param (
    [string]$host_path = $(throw "-host_path is required."),
    [string]$guest_path = $(throw "-guest_path is required."),
    [string]$guest_ip = $(throw "-guest_ip is required."),
    [string]$guest_port = $(throw "-guest_port is required."),
    [string]$username = $(throw "-guest_username is required."),
    [string]$password = $(throw "-guest_password is required.")
 )

# Include the following modules
$presentDir = Split-Path -parent $PSCommandPath
. ([System.IO.Path]::Combine($presentDir, "utils\write_messages.ps1"))
. ([System.IO.Path]::Combine($presentDir, "utils\create_session.ps1"))

try {
  function Copy-File-To-VM($path, $content) {
    if (!(Test-Path $path)) {
      $folder = Split-Path $path
      New-Item $folder -type directory -Force
    }

    [IO.File]::WriteAllBytes($path, $content)
  }

  function Upload-FIle-To-VM($host_path, $guest_path, $session) {
    $contents = [IO.File]::ReadAllBytes($host_path)
    Invoke-Command -Session $session -ScriptBlock ${function:Copy-File-To-VM} -ArgumentList $guest_path,$contents
  }

  function Prepare-Guest-Folder($session) {
    # Create the guest folder if not exist
    $result = Invoke-Command -Session $session -ScriptBlock ${function:Create-Guest-Folder} -ArgumentList $guest_path
  }

  function Create-Guest-Folder($guest_path) {
    try {
      if (Test-Path $guest_path) {
        # First attempt to remove a Junction drive. The fall back to removing a
        # folder
        $junction = Get-Item $guest_path
        $junction.Delete()
      }
    }
    # Catch any [IOException]
     catch {
       Remove-Item "$guest_path" -Force -Recurse
     }
     New-Item "$guest_path" -type directory -Force
  }

  $response = Create-Remote-Session $guest_ip $guest_port $username $password
  if (!$response["session"] -and $response["error"]) {
    $errortHash = @{
      type = "PowerShellError"
      error = $response["error"]
    }
    Write-Error-Message $errortHash
    return
  }
  $session = $response["session"]

  # When Host path is a folder.
  # Find all files within it and copy to the Guest
  if (Test-Path $host_path -pathtype container) {
    # Open a remote PS Session with the guest
    Prepare-Guest-Folder $session
    # Copy all files from Host path to Guest Path
    Get-ChildItem $host_path -rec |
      Where-Object {$_.PSIsContainer -eq $false} |
        ForEach-Object -Process {
          $file_name = $_.Fullname.SubString($host_path.length)
          $from = $host_path + $file_name
          $to = $guest_path + $file_name
          Upload-FIle-To-VM $from $to $session
        }
  } elseif (Test-Path $host_path) {
    Upload-FIle-To-VM $host_path $guest_path $session
  }
  $resultHash = @{
    message = "OK"
  }
  Write-Output-Message $resultHash
} catch {
  $errortHash = @{
    type = "PowerShellError"
    error ="Failed to copy file $_"
  }
  Write-Error-Message $errortHash
  return
}

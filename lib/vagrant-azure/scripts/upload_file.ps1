#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
#--------------------------------------------------------------------------

param (
    [string]$vm_id = $(throw "-vm_id is required."),
    [string]$host_path = $(throw "-host_path is required."),
    [string]$guest_path = $(throw "-guest_path is required."),
    [string]$guest_ip = $(throw "-guest_ip is required."),
    [string]$username = $(throw "-guest_username is required."),
    [string]$password = $(throw "-guest_password is required.")
 )

# Include the following modules
$presentDir = Split-Path -parent $PSCommandPath
. ([System.IO.Path]::Combine($presentDir, "utils\write_messages.ps1"))
. ([System.IO.Path]::Combine($presentDir, "utils\create_session.ps1"))

try {
  # Enable Guest Service Interface if they are disabled
  try {
    Get-VM -Id $vm_id | Get-VMIntegrationService -Name "Guest Service Interface" | Enable-VMIntegrationService -Passthru
    }
    catch { }

  function Upload-FIle-To-VM($host_path, $guest_path, $machine) {
    Write-Host $host_path
    Write-Host $guest_path
    Copy-VMFile  -VM $machine -SourcePath $host_path -DestinationPath $guest_path -CreateFullPath -FileSource Host -Force -ErrorAction stop
  }

  function Prepare-Guest-Folder($guest_ip, $username, $password) {
    $response = Create-Remote-Session $guest_ip $username $password
    if (!$response["session"] -and $response["error"]) {
      $errortHash = @{
        type = "PowerShellError"
        message = $response["error"]
      }
      Write-Error-Message $errorResult
      return
    }
    $session = $response["session"]
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

  $machine = Get-VM -Id $vm_id
  # When Host path is a folder.
  # Find all files within it and copy to the Guest
  if (Test-Path $host_path -pathtype container) {
    # Open a remote PS Session with the guest
    Prepare-Guest-Folder $guest_ip $username $password
    # Copy all files from Host path to Guest Path
    Get-ChildItem $host_path -rec |
      Where-Object {$_.PSIsContainer -eq $false} |
        ForEach-Object -Process {
          $file_name = $_.Fullname.Replace($host_path, "")
          $from = $host_path + $file_name
          $to = $guest_path + $file_name
          # Write-Host $from
          # Write-Host $to
          Upload-FIle-To-VM $from $to $machine
        }
  } elseif (Test-Path $host_path) {
    Upload-FIle-To-VM $host_path $guest_path $machine
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

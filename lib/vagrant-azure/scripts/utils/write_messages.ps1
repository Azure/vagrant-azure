#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the Apache 2.0 License.
#--------------------------------------------------------------------------

function Write-Error-Message($message) {
  $result = ConvertTo-Json $message
  Write-Host "===Begin-Error==="
  Write-Host $result
  Write-Host "===End-Error==="
}

function Write-Output-Message($message) {
  $result = ConvertTo-Json $message
  Write-Host "===Begin-Output==="
  Write-Host $result
  Write-Host "===End-Output==="
}

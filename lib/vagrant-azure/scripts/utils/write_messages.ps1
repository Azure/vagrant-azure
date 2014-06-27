#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
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

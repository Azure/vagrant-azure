#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved.  Licensed under the Apache License, Version 2.0.
# See License.txt in the project root for license information.
#--------------------------------------------------------------------------

function Get-Remote-Session($guest_ip, $guest_port, $username, $password) {
    $secstr = convertto-securestring -AsPlainText -Force -String $password
    $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr
    New-PSSession -ComputerName $guest_ip -Port $guest_port -Credential $cred -UseSSL -ErrorAction "stop"
}

function Create-Remote-Session($guest_ip, $guest_port, $username, $password) {
    $count = 0
    $session_error = ""
    $session = ""
    do {
        $count++
        try {
            $session = Get-Remote-Session $guest_ip $guest_port $username $password
            $session_error = ""
        }
        catch {
            Start-Sleep -s 1
            $session_error = $_
            $session = ""
        }
    }
    while (!$session -and $count -lt 20)

    return  @{
        session = $session
        error = "$session_error"
    }
}

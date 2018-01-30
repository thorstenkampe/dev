#! /usr/bin/env pwsh

<#
.SYNOPSIS
DESCRIPTION

.DESCRIPTION
`SCRIPT` DESCRIPTION
#>

[CmdletBinding(SupportsShouldProcess)]
param(
)

## INITIALIZATION ##
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest

## DEBUGGING ##
# script is run with `-Debug`
if ($DebugPreference -eq 'Inquire') {
    $DebugPreference = 'Continue'
}

Write-Debug -Message ('PowerShell {0}' -f $PSVersionTable.PSVersion)
if ($DebugPreference -eq 'Continue') {
    Set-PSDebug -Trace 1
}

try {
## MAIN CODE STARTS HERE ##

}
finally {
    Set-PSDebug -Trace 0
}

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

Write-Debug -Message ('PowerShell {0} {1}' -f $PSEdition,
                                              $PSVersionTable.PSVersion)
if ($DebugPreference -eq 'Continue') {
    Set-PSDebug -Trace 1
}

try {
## MAIN CODE STARTS HERE ##

## MAIN CODE ENDS HERE ##
}
finally {
    Set-PSDebug -Trace 0
}

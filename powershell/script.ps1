#! /usr/bin/env pwsh

<#
.SYNOPSIS
DESCRIPTION

.DESCRIPTION
`SCRIPT` DESCRIPTION
#>

[CmdletBinding(PositionalBinding = $false)]
param(
)

## INITIALIZATION ##
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest

## DEBUGGING ##
# script is run with `-debug`
if ($DebugPreference -eq 'Inquire') {
    $DebugPreference = 'Continue'
}

Write-Debug -Message "PowerShell $($PSVersionTable.PSVersion.ToString())"
if ($DebugPreference -eq 'Continue') {
    Set-PSDebug -Trace 1
}

## MAIN CODE STARTS HERE ##

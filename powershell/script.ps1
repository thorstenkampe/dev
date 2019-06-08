#! /usr/bin/env pwsh

<#
.SYNOPSIS
DESCRIPTION

.DESCRIPTION
`SCRIPT` DESCRIPTION
#>

# INITIALIZATION #
[CmdletBinding(SupportsShouldProcess)]
Param([Switch] $Help)  # make help available the standard way (without `Get-Help`)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest

# HELP #
if ($Help) {
    Get-Help -Name $MyInvocation.InvocationName -Full
    exit 1
}

# DEBUGGING #
Write-Debug -Message ('PowerShell {0} {1}' -f $PSEdition, $PSVersionTable.PSVersion)
# script is run with `-Debug`
if ($DebugPreference -eq 'Continue') {
    Set-PSDebug -Trace 1
}

# MAIN CODE STARTS HERE #

#
Set-PSDebug -Trace 0

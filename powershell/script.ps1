#! /usr/bin/env pwsh

<#
.SYNOPSIS
DESCRIPTION

.DESCRIPTION
`SCRIPT` DESCRIPTION
#>

[CmdletBinding(SupportsShouldProcess)]
Param([Switch] $Help)  # make help available the standard way (without `Get-Help`)

#region INITIALIZATION #
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest
#endregion

#region HELP #
if ($Help) {
    Get-Help -Name $MyInvocation.InvocationName -Full
    exit 1
}
#endregion

#region DEBUGGING #
Write-Debug -Message ('PowerShell {0} {1}' -f $PSEdition, $PSVersionTable.PSVersion)
# script is run with `-Debug`
if ($DebugPreference -eq 'Continue') {
    Set-PSDebug -Trace 1
}
#endregion

try {
#region MAIN CODE STARTS HERE #

#endregion
}
finally {
    Set-PSDebug -Trace 0
}

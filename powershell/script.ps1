#! /usr/bin/env pwsh

<#
.SYNOPSIS
DESCRIPTION

.DESCRIPTION
`SCRIPT` DESCRIPTION
#>

# * https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_cmdletbindingattribute
# * https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters
[CmdletBinding(SupportsShouldProcess)]
Param([Switch] $Help)

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
# script is run with `-Debug`
if ($DebugPreference -eq 'Inquire') {
    $DebugPreference = 'Continue'
}

Write-Debug -Message ('PowerShell {0} {1}' -f $PSEdition,
                                              $PSVersionTable.PSVersion)
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

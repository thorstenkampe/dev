#! /usr/bin/env pwsh

<#
.SYNOPSIS
DESCRIPTION

.DESCRIPTION
SCRIPT DESCRIPTION
#>

[CmdletBinding(SupportsShouldProcess)]
Param([Switch] $Help)  # make help available without `Get-Help`

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest

# LOGGING #
# modeled after Python modules `logging` and `colorlog`
$verbosity = 'WARNING'  # default level
$loglevel  = @{CRITICAL = 10; ERROR = 20; WARNING = 30; INFO = 40; DEBUG = 50}
$color     = @{CRITICAL = 'Red'; ERROR = 'DarkRed'; WARNING = 'DarkYellow'; INFO = 'DarkGreen'; DEBUG = 'Gray'}

function log {
    if ($loglevel[$args[0]] -le $loglevel[$verbosity]) {
        Write-Host -Object $args[0] -ForegroundColor $color[$args[0]] -NoNewline
        Write-Host -Object (": {0}" -f $args[1])
    }
}

# OPTIONS #
if     ($Help) {                              # `-Help`
    Get-Help -Name $MyInvocation.InvocationName -Full
    exit 1
}
elseif ($VerbosePreference -eq 'Continue') {  # `-Verbose`
    $verbosity = 'INFO'
}
elseif ($DebugPreference -eq 'Continue') {    # `-Debug`
    $verbosity = 'DEBUG'
    log DEBUG ("PowerShell $PSEdition {0}" -f $PSVersionTable.PSVersion)
    Set-PSDebug -Trace 1
}

# MAIN CODE STARTS HERE #

#
Set-PSDebug -Trace 0

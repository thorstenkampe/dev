#! /usr/bin/env pwsh

<#
.SYNOPSIS
DESCRIPTION

.DESCRIPTION
SCRIPT DESCRIPTION
#>

[CmdletBinding(SupportsShouldProcess)]  # support for `ShouldProcess` and `ShouldContinue`
Param([Switch] $Help)                   # make help available without `Get-Help`

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest

# LOGGING #
# modeled after Python modules `logging` and `colorlog`
$verbosity = 'WARNING'  # default level
$loglevel  = @{CRITICAL = 50; ERROR = 40; WARNING = 30; INFO = 20; DEBUG = 10}
$color     = @{CRITICAL = 'Red'; ERROR = 'DarkRed'; WARNING = 'DarkYellow'; INFO = 'DarkGreen'; DEBUG = 'Gray'}

function log($Level, $Message) {
    if ($loglevel[$Level] -ge $loglevel[$verbosity]) {
        Write-Host -Object $Level -ForegroundColor $color[$Level] -NoNewline
        Write-Host -Object (": {0}" -f $Message)
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
    log -Level DEBUG -Message ("PowerShell $PSEdition {0}" -f $PSVersionTable.PSVersion)
    Set-PSDebug -Trace 1
}

# MAIN CODE STARTS HERE #

#
Set-PSDebug -Trace 0

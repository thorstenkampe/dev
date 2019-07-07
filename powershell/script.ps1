﻿<#
.SYNOPSIS
DESCRIPTION

.DESCRIPTION
SCRIPT DESCRIPTION

.PARAMETER Help
show detailed help

.PARAMETER WhatIf
show what the script would do (dry run)

.PARAMETER Confirm
confirm the script's actions
#>

# INITIALIZATION #
# support `-Verbose`, `-Debug`, `-WhatIf`, `-Confirm`, `ShouldProcess()`, and
# `ShouldContinue()`
[CmdletBinding(SupportsShouldProcess)]
Param([Switch] $Help)  # make help available without `Get-Help`

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest

# https://stackoverflow.com/questions/2379514/powershell-formatting-values-in-another-culture/
$old_culture = [cultureinfo]::currentculture
[cultureinfo]::currentculture = [cultureinfo]::InvariantCulture  # "neutral" environment

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

# DEFAULT OPTIONS #
if     ($Help) {                              # `-Help`
    Get-Help -Name $MyInvocation.InvocationName -Detailed
    exit
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
try {
    # test command to demonstrate `-WhatIf` and `-Confirm`
    New-Variable -Name TEST_VAR -Value test_value
}
finally {
    [cultureinfo]::currentculture = $old_culture
    Set-PSDebug -Trace 0
}

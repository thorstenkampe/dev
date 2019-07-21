# INITIALIZATION #
[CmdletBinding()]
Param([Switch] $Help)  # make help available without `Get-Help`
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest
[cultureinfo]::currentculture = [cultureinfo]::InvariantCulture  # "neutral" environment

Import-Module -Name PSWriteColor

# LOGGING #
$verbosity = 'WARNING'  # default level
$loglevel  = @{CRITICAL = 50; ERROR = 40; WARNING = 30; INFO = 20; DEBUG = 10}
$color     = @{CRITICAL = 'Red'; ERROR = 'DarkRed'; WARNING = 'DarkYellow'; INFO = 'DarkGreen'}

function log($Level, $Message) {
    if ($loglevel[$Level] -ge $loglevel[$verbosity]) {
        Write-Color -Text $Level, ": $Message" -Color $color[$Level], Gray
    }
}

# OPTIONS #
if ($Help) {  # `-Help`
    Get-Help -Name $MyInvocation.InvocationName
    exit
}

# MAIN CODE STARTS HERE #

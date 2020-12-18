# INITIALIZATION #
[CmdletBinding()]
Param(
    [Switch] $Help  # make help available without `Get-Help`
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest
[cultureinfo]::currentculture = [cultureinfo]::InvariantCulture  # "neutral" environment

# OPTIONS #
if ($Help) {  # `-Help`
    Get-Help -Name $MyInvocation.InvocationName
    exit
}

# MAIN CODE STARTS HERE #

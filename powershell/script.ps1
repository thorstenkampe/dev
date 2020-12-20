# initialization #
[CmdletBinding()]
Param(
    [Parameter(Mandatory, ParameterSetName='Help')]
    [Switch] $Help  # make help available without `Get-Help`
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest
[cultureinfo]::currentculture = [cultureinfo]::InvariantCulture  # "neutral" environment

# options #
if ($Help) {  # `-Help`
    Get-Help -Name $MyInvocation.InvocationName
    exit
}

# MAIN CODE STARTS HERE #

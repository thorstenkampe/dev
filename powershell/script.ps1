# enable debugging with `Set-PSDebug -Trace 1`

Param(
    [Parameter(ParameterSetName='Help')]
    [Switch] $Help  # make help available without `Get-Help`
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest
[cultureinfo]::currentculture = [cultureinfo]::InvariantCulture  # "neutral" environment

function log($Level, $Message) {
    Write-Output -InputObject "${Level}: $Message"
}

if ($Help) {  # `-Help`
    Get-Help -Name $MyInvocation.InvocationName
    exit
}

# MAIN CODE STARTS HERE #

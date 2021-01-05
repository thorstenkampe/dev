Param(
    [Parameter(ParameterSetName='Help')]
    [Switch] $Help
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest

$script = $MyInvocation.InvocationName

function Show-Help {
    Get-Help -Name $script
    exit
}

if ($Help) {
    Show-Help
}

# MAIN CODE STARTS HERE #

if (-not $Help) {
    Show-Help
}


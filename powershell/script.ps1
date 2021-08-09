Param(
    [Parameter(ParameterSetName='Help')]
    [Switch] $Help
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest

. $PSScriptRoot\toolbox.ps1

$script = $MyInvocation.InvocationName

if ($Help) {
    Get-Help -Name $script
    exit
}

# MAIN CODE STARTS HERE #

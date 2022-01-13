Param(
    [Parameter(ParameterSetName='Help')]
    [Switch] $Help
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest

. $PSScriptRoot\toolbox.ps1

if ($Help) {
    Get-Help -Name $MyInvocation.InvocationName
    exit
}

# MAIN CODE STARTS HERE #

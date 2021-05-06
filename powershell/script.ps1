Param(
    [Parameter(ParameterSetName='Help')]
    [Switch] $Help
)

. $PSScriptRoot\toolbox.ps1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest

$script    = $MyInvocation.InvocationName
$verbosity = 'WARNING'  # default level

if ($Help) {
    Get-Help -Name $script
    exit
}

# MAIN CODE STARTS HERE #

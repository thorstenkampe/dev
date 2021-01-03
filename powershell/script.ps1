Param(
    [Parameter(ParameterSetName='Help')]
    [Switch] $Help
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest
[cultureinfo]::currentculture = [cultureinfo]::InvariantCulture  # "neutral" environment

if ($DebugPreference -eq 'Continue') {
    Write-Debug -Message '!! turn off debug tracing with `Set-PSDebug -Off`'
    Set-PSDebug -Trace 1
}

# MAIN CODE STARTS HERE #

if ($Help) {
    Write-Output -InputObject 'script.ps1 [-Help] [-Debug]'
    exit
}

Param(
    [Parameter(ParameterSetName='Help')]
    [Switch] $Help
)

$usage = @'
script.ps1 [-Help]
'@

#
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest

if ($Help) {
    Write-Output -InputObject $usage
    exit
}

# MAIN CODE STARTS HERE #

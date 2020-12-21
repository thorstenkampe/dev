# initialization #
# enable debugging with `Set-PSDebug -Trace 1`
Param(
    [Parameter(ParameterSetName='Help')]
    [Switch] $Help  # make help available without `Get-Help`
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest
[cultureinfo]::currentculture = [cultureinfo]::InvariantCulture  # "neutral" environment

# logging #
function log($Level, $Message) {
    $date = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Output -InputObject "$date ${Level}: $Message"
}

# options #
if ($Help) {  # `-Help`
    Get-Help -Name $MyInvocation.InvocationName
    exit
}

# MAIN CODE STARTS HERE #

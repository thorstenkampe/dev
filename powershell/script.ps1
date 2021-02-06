Param(
    [Parameter(ParameterSetName='Help')]
    [Switch] $Help
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest

$script    = $MyInvocation.InvocationName
$verbosity = 'WARNING'  # default level

function log($Level, $Message) {
    $loglevel = @{CRITICAL = 50; ERROR = 40; WARNING = 30; INFO = 20; DEBUG = 10}

    if ($loglevel[$Level] -ge $loglevel[$verbosity]) {
        Write-Output -InputObject "${Level}: $Message"
    }
}

function Show-Help {
    Get-Help -Name $script
    exit
}

if ($Help) {
    Show-Help
}

# MAIN CODE STARTS HERE #

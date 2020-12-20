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
    $color = @{
        CRITICAL = 'Red'
        ERROR    = 'DarkRed'
        WARNING  = 'DarkYellow'
        INFO     = 'DarkGreen'
        DEBUG    = 'Gray'
    }

    Write-Color -Text $Level, ": $Message"  `
                -Color $color[$Level], Gray `
                -ShowTime
}

# options #
if ($Help) {  # `-Help`
    Get-Help -Name $MyInvocation.InvocationName
    exit
}

# MAIN CODE STARTS HERE #

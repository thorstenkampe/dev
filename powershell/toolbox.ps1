﻿# - tb_abspath #
function tb_abspath($Path) {
    # https://github.com/PowerShell/PowerShell/issues/10278
    [IO.Path]::GetFullPath($Path, (Convert-Path -Path '.'))
}

# - tb_get_proxy #
function tb_get_proxy {
    try {
        (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings').ProxyServer
    }
    catch [Management.Automation.PropertyNotFoundException] {
        $null
    }
}

# - tb_ident #
function tb_ident {
    $args
}

# - tb_is_admin #
function tb_is_admin {
	[Boolean] ([Security.Principal.WindowsIdentity]::GetCurrent().UserClaims | Where-Object {$PSItem.Value -eq 'S-1-5-32-544'})
}

# - tb_is_domain #
function tb_is_domain {
    if ($IsWindows) {
        (Get-CimInstance -ClassName win32_computersystem).partofdomain
    }
    else {
        $false
    }
}

# - tb_is_elevated #
# https://ss64.com/ps/syntax-elevate.html
function tb_is_elevated {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
}

# - tb_is_port_reachable #
function tb_is_port_reachable($Server, $Port) {
    Test-Connection -TargetName $Server -TcpPort $Port -TimeoutSeconds 1 -Quiet
}

# - tb_is_pscore #
function tb_is_pscore {
    $PSVersionTable.PSEdition -eq 'Core'
}

# - tb_is_windows #
# `$IsWindows` does not exist on PowerShell Desktop
function tb_is_windows {
    try {
        $IsWindows -or -not (tb_is_pscore)
    }
    catch [Management.Automation.RuntimeException] {
        $true
    }
}

# - tb_reset #
function tb_reset {
    [Console]::ResetColor()
}

# - tb_second_ext #
function tb_second_ext($Name) {
    Split-Path -Path (Split-Path -Path $Name -LeafBase) -Extension
}

# - tb_Set-EnvironmentVariable #
# modifying the persistent environment is expensive so we only update if environment
# value differs
function tb_Set-EnvironmentVariable($Name, $Scope, $Value) {
        if ([environment]::getEnvironmentVariable($name, $Scope) -ne $value) {
            [environment]::setEnvironmentVariable($name, $value, $Scope)
        }
}

##
# - tb_arc #
function tb_arc {
    Param(
        [Parameter(Mandatory, ParameterSetName='Compress')]
        [Switch] $Compress,

        [Parameter(Mandatory, ParameterSetName='Extract')]
        [Switch] $Extract,

        [Parameter(Mandatory, Position=0)]
        [String] $Source,

        [Parameter(Mandatory, ParameterSetName='Compress')]
        [Parameter(ParameterSetName='Extract')]
        [Parameter(Position=1)]
        [String] $Destination = '.'
    )

    if ($Compress) {
        if ((tb_second_ext $Destination) -eq '.tar') {
            $name   = Split-Path -Path $Source -Leaf
            $parent = Split-Path -Path $Source -Parent

            tar -caf (cygpath $Destination) -C $parent $name @args
        }
        else {
            7z a -ssw $Destination (abspath -Path $Source) @args
        }
    }
    else {
        if ((tb_second_ext $Source) -eq '.tar') {
            tar -xaf (cygpath $Source) -C (cygpath $Destination) @args
        }
        else {
            7z x $Source -o"$Destination" -y @args
        }
    }
}

# - tb_choice #
function tb_choice($Prompt, $Answers) {
    do {
        $selection = Read-Host -Prompt $prompt
        if ($selection -in $answers) {
            break
        }
    }
    until ($false)

    $selection
}

# - tb_Clean-Path #
function tb_Clean-Path($paths) {
    # Remove duplicate and non-existing paths from delimited path string
    $paths = $paths -split [IO.Path]::PathSeparator
    $paths = $paths | Select-Object -Unique | Where-Object {Test-Path -Path $PSItem -PathType Container}
    $paths -join [IO.Path]::PathSeparator
}

# - tb_color #
function tb_color {
    # https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
    if (tb_is_pscore) {
        $global:color = @{
            # foreground  bright     background   bright
            k="`e[30m"; bK="`e[90m"; _k="`e[40m"; _bK="`e[100m"  # black
            r="`e[31m"; bR="`e[91m"; _r="`e[41m"; _bR="`e[101m"  # red
            g="`e[32m"; bG="`e[92m"; _g="`e[42m"; _bG="`e[102m"  # green
            y="`e[33m"; bY="`e[93m"; _y="`e[43m"; _bY="`e[103m"  # yellow
            b="`e[34m"; bB="`e[94m"; _b="`e[44m"; _bB="`e[104m"  # blue
            m="`e[35m"; bM="`e[95m"; _m="`e[45m"; _bM="`e[105m"  # magenta
            c="`e[36m"; bC="`e[96m"; _c="`e[46m"; _bC="`e[106m"  # cyan
            w="`e[37m"; bW="`e[97m"; _w="`e[47m"; _bW="`e[107m"  # white
            0="`e[m"                                             # reset
        }
    } else {
        $global:color = @{}
    }
}

# - tb_ConvertTo-Ordered #
function tb_ConvertTo-Ordered($Hash) {
    # Shallow copy of the original (see comment for dmap)
    $dict = [ordered]@{}
    $keys = $Hash.Keys | Sort-Object

    foreach ($key in $keys) {
        $dict[$key] = $Hash[$key]
    }

    $dict
}

# - tb_dmap #
function tb_dmap($hash, $Keyfunc) {
    # Modifies the original. Cloning a hash is shallow and not supported for ordered
    # dictionaries. Copying with "(foreach key {clone[key] = orig[key]})" is also
    # shallow
    foreach ($key in @($hash.Keys)) {
        $hash[$key] = & $Keyfunc $hash[$key]
    }
}

# - tb_dupdate #
function tb_dupdate($hash1, $hash2) {
    if ($hash2) {
        foreach ($key in $hash2.Keys) {
            $hash1.$key = $hash2.$key
        }
    }
}

# - tb_exec #
# * https://rkeithhill.wordpress.com/2009/08/03/effective-powershell-item-16-dealing-with-errors/
# * http://codebetter.com/jameskovacs/2010/02/25/the-exec-problem/
# * `tb_exec -Cmd {false}`
function tb_exec($Cmd) {
    & $cmd
    if ($LASTEXITCODE -ne 0) {
        throw "Command terminated with exit code $LastExitCode"
    }
}

# - tb_groupby #
# https://www.powershellmagazine.com/2013/12/23/simplifying-data-manipulation-in-powershell-with-lambda-functions/
function tb_groupby($object, $keyfunc='ident') {
    # * `tb_groupby $array {param($x) $x.gettype().Name}`
    # * `tb_groupby $hashtable {param($x) $x.Value.GetType().Name}`
    $object.GetEnumerator() | Group-Object -Property {& $keyfunc $PSItem} -AsHashTable
}

# - tb_log #
function tb_log($Level, $Message) {
    $loglevel   = @{error=10;    warn=20;       info=30;      debug=40}
    # `[Enum]::GetValues([ConsoleColor])`
    $colorlevel = @{error='red'; warn='yellow'; info='white'; debug='blue'}
    $prefix     = "[$($Level.ToUpper())] "

    if (-not (Test-Path -Path variable:verbosity)) {
        $verbosity = 'warn'  # default level
    }

    if ($loglevel[$Level] -le $loglevel[$verbosity]) {
        try {
            Write-Host -Object $prefix -ForegroundColor $colorlevel[$Level] -NoNewline
        }
        catch [Management.Automation.ParameterBindingException] {
            Write-Host -Object $prefix -NoNewline
        }
        Write-Host -Object $Message
    }
}

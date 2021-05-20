#  - abspath #
function abspath($Path) {
    # https://github.com/PowerShell/PowerShell/issues/10278
    [System.IO.Path]::GetFullPath($Path, (Convert-Path -Path '.'))
}

#  - get_proxy #
function get_proxy {
    try {
        (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings').ProxyServer
    }
    catch [Management.Automation.PropertyNotFoundException] {
        $null
    }
}

#  - ident #
function ident {
    $args
}

#  - is_domain #
function is_domain {
    if ($IsWindows) {
        (Get-CimInstance -ClassName win32_computersystem).partofdomain
    }
    else {
        $false
    }
}

# - is_elevated #
# https://ss64.com/ps/syntax-elevate.html
function is_elevated {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
}

# - second_ext #
function second_ext($Name) {
    Split-Path -Path (Split-Path -Path $Name -LeafBase) -Extension
}

##
# arc #
function arc {
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
        if ((second_ext $Destination) -eq '.tar') {
            $name   = Split-Path -Path $Source -Leaf
            $parent = Split-Path -Path $Source -Parent

            tar -caf (cygpath $Destination) -C $parent $name @args
        }
        else {
            7z a -ssw $Destination (abspath -Path $Source) @args
        }
    }
    else {
        if ((second_ext $Source) -eq '.tar') {
            tar -xaf (cygpath $Source) -C (cygpath $Destination) @args
        }
        else {
            7z x $Source -o"$Destination" -y @args
        }
    }
}

# - choice #
function choice($Prompt, $Answers) {
    do {
        $selection = Read-Host -Prompt $prompt
        if ($selection -in $answers) {
            break
        }
    }
    until ($false)

    $selection
}

function color {
    # https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
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
}

#  - ConvertTo-Ordered #
function ConvertTo-Ordered($Hash) {
    # Shallow copy of the original (see comment for dmap)
    $dict = [ordered]@{}
    $keys = $Hash.Keys | Sort-Object

    foreach ($key in $keys) {
        $dict[$key] = $Hash[$key]
    }

    $dict
}

#  - dmap #
function dmap($hash, $Keyfunc) {
    # Modifies the original. Cloning a hash is shallow and not supported for ordered
    # dictionaries. Copying with "(foreach key {clone[key] = orig[key]})" is also
    # shallow
    foreach ($key in @($hash.Keys)) {
        $hash[$key] = & $Keyfunc $hash[$key]
    }
}

#  - dupdate #
function dupdate($hash1, $hash2) {
    if ($hash2) {
        foreach ($key in $hash2.Keys) {
            $hash1.$key = $hash2.$key
        }
    }
}

# - exec #
# * https://rkeithhill.wordpress.com/2009/08/03/effective-powershell-item-16-dealing-with-errors/
# * http://codebetter.com/jameskovacs/2010/02/25/the-exec-problem/
# * `exec -Cmd {false}`
function exec($Cmd) {
    & $cmd
    if ($LASTEXITCODE -ne 0) {
        throw "Command terminated with exit code $LastExitCode"
    }
}

#  - groupby #
# https://www.powershellmagazine.com/2013/12/23/simplifying-data-manipulation-in-powershell-with-lambda-functions/
function groupby($object, $keyfunc='ident') {
    # * `groupby $array {param($x) $x.gettype().Name}`
    # * `groupby $hashtable {param($x) $x.Value.GetType().Name}`
    $object.GetEnumerator() | Group-Object -Property {& $keyfunc $PSItem} -AsHashTable
}

# - log #
function log($Level, $Message) {
    color
    $loglevel   = @{error=10;           warn=20;           info=30;           debug=40}
    $colorlevel = @{error=$color['bR']; warn=$color['bY']; info=$color['bW']; debug=$color['bB']}

    if (-not (Test-Path -Path variable:verbosity)) {
        $verbosity = 'warn'  # default level
    }

    if ($loglevel[$Level] -le $loglevel[$verbosity]) {
        Write-Output -InputObject ("{0}[$($Level.ToUpper())]{1} $Message" -f $colorlevel[$Level], $color[0])
    }
}

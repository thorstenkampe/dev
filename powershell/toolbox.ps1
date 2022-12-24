function tb_abspath($Path) {
    # https://github.com/PowerShell/PowerShell/issues/10278
    [IO.Path]::GetFullPath($Path, (Convert-Path -Path '.'))
}

function tb_get_proxy {
    try {
        (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings').ProxyServer
    }
    catch [Management.Automation.PropertyNotFoundException] {
        $null
    }
}

function tb_is_admin {
	[Boolean] ([Security.Principal.WindowsIdentity]::GetCurrent().UserClaims | Where-Object {$PSItem.Value -eq 'S-1-5-32-544'})
}

function tb_is_domain {
    if ($IsWindows) {
        (Get-CimInstance -ClassName win32_computersystem).partofdomain
    }
    else {
        $false
    }
}

function tb_is_elevated {
    # https://ss64.com/ps/syntax-elevate.html
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
}

function tb_port_reachable($Server, $Port) {
    Test-Connection -TargetName $Server -TcpPort $Port -TimeoutSeconds 1 -Quiet
}

function tb_is_pscore {
    $PSVersionTable.PSEdition -eq 'Core'
}

function tb_is_windows {
    # `$IsWindows` does not exist on PowerShell Desktop
    -not (tb_is_pscore) -or $IsWindows
}

function tb_Set-EnvironmentVariable($Name, $Scope, $Value) {
    # modifying the persistent environment is expensive so we only update if environment
    # value differs
    if ([environment]::getEnvironmentVariable($Name, $Scope) -ne $Value) {
        [environment]::setEnvironmentVariable($Name, $Value, $Scope)
    }
}

function tb_uac_enabled {
    [bool] (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System).EnableLUA
}

##
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

    function second_ext($Name) {
        Split-Path -Path (Split-Path -Path $Name -LeafBase) -Extension
    }

    if ($Compress) {
        if ((second_ext $Destination) -eq '.tar') {
            $name   = Split-Path -Path $Source -Leaf
            $parent = Split-Path -Path $Source -Parent

            tar -caf $Destination -C $parent $name @args
        }
        else {
            7z a -ssw $Destination (abspath -Path $Source) @args
        }
    }
    else {
        if ((second_ext $Source) -eq '.tar') {
            tar -xaf $Source -C $Destination @args
        }
        else {
            7z x $Source -o"$Destination" -y @args
        }
    }
}

function tb_choice($Prompt, $Answers) {
    do {
        $selection = Read-Host -Prompt $Prompt
        if ($selection -in $Answers) {
            break
        }
    }
    until ($false)
    $selection
}

function tb_Clean-Path($paths) {
    # Remove duplicate and non-existing paths from delimited path string
    $paths = $paths -split [IO.Path]::PathSeparator
    $paths = $paths | Select-Object -Unique | Where-Object {Test-Path -Path $PSItem -PathType Container}
    $paths -join [IO.Path]::PathSeparator
}

function tb_map($Keyfunc, $Collection) {
    try {
        $indices = @($Collection.Keys)
    }
    catch [Management.Automation.PropertyNotFoundException] {
        $indices = 0 .. ($Collection.Length - 1)
    }

    foreach ($index in $indices) {
        $Collection[$index] = & $Keyfunc $Collection[$index]
    }
}

function tb_exec($Cmd) {
    # * https://rkeithhill.wordpress.com/2009/08/03/effective-powershell-item-16-dealing-with-errors/
    # * https://web.archive.org/web/20150427174442/http://codebetter.com/jameskovacs/2010/02/25/the-exec-problem/
    # * `tb_exec -Cmd {false}`
    & $cmd
    if ($LASTEXITCODE -ne 0) {
        # creates `Management.Automation.RuntimeException`
        throw "Command terminated with exit code $LastExitCode"
    }
}

function tb_groupby($Keyfunc={param($x) $x}, $Collection) {
    # * https://www.powershellmagazine.com/2013/12/23/simplifying-data-manipulation-in-powershell-with-lambda-functions/
    # * `tb_groupby {param($x) $x.gettype().Name} $test_array`
    # * `tb_groupby {param($x) $x.Value.GetType().Name} $test_hashtable`
    if (tb_is_pscore) {
        $params = @{'-CaseSensitive' = $true}
    }
    else {
        # error in PowerShell Desktop with `-CaseSensitive` ("key duplication")
        $params = @{'-AsString' = $true}
    }
    $Collection.GetEnumerator() | Group-Object -Property {& $keyfunc $PSItem} -AsHashTable @params
}

function tb_init {
	$Env:LC_ALL = 'POSIX'
}

function tb_log($Level, $Message) {
    $loglevel   = @{error=10;    warn=20;       info=30;      debug=40}
    # `[Enum]::GetValues([ConsoleColor])`
    $colorlevel = @{error='red'; warn='yellow'; info='white'; debug='blue'}
    $prefix     = "[$($Level.ToUpper())] "

    if (-not (Test-Path -Path variable:verbosity)) {
        $verbosity = 'info'  # default level
    }

    if ($loglevel[$Level] -le $loglevel[$verbosity]) {
        Write-Host -Object $prefix -ForegroundColor $colorlevel[$Level] -NoNewline
        Write-Host -Object $Message
    }
}

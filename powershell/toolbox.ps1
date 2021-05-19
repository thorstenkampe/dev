#  - ident #
function ident {
    $args
}

# - is_elevated #
# https://ss64.com/ps/syntax-elevate.html
function is_elevated {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
}

##
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
    $loglevel   = @{error = 10;    warn = 20;       info = 30;      debug = 40}
    $colorlevel = @{error = 'red'; warn = 'yellow'; info = 'white'; debug = 'blue'}
    $prefix     = "[$($Level.ToUpper())] "

    if (-not (Test-Path -Path variable:verbosity)) {
        $verbosity = 'warn'  # default level
    }

    if ($loglevel[$Level] -le $loglevel[$verbosity]) {
        if ($colorlevel.ContainsKey($Level)) {
            Write-Color -Text $prefix -Color $colorlevel[$Level] -NoNewLine
            Write-Output -InputObject $Message
        } else {
            Write-Output -InputObject $prefix$Message
        }
    }
}

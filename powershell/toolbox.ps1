#  - ident #
function ident {
    $args
}

# arcc #
function arcc($Source, $Target) {
    $target_ext = Split-Path -Path $Target -Extension

    if ($target_ext -eq '.zip') {
        $Source = [System.IO.Path]::GetFullPath($Source)
        7z a -ssw $Target $Source @args
    }
    else {
        $name   = Split-Path -Path $Source -Leaf
        $parent = Split-Path -Path $Source -Parent
        $Target = cygpath $Target

        tar -caf $Target -C $parent $name @args
    }
}

# arcx #
function arcx($Source, $Target) {
    $source_ext = Split-Path -Path $Source -Extension

    if ($source_ext -eq '.zip') {
        7z x $Source -o"$Target" * @args
    }
    else {
        $Source = cygpath $Source
        $Target = cygpath $Target
        tar -xaf $Source -C $Target @args
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

#  - groupby #
# https://www.powershellmagazine.com/2013/12/23/simplifying-data-manipulation-in-powershell-with-lambda-functions/
function groupby($object, $keyfunc='ident') {
    # * `groupby $array {param($x) $x.gettype().Name}`
    # * `groupby $hashtable {param($x) $x.Value.GetType().Name}`
    $object.GetEnumerator() | Group-Object -Property {& $keyfunc $PSItem} -AsHashTable
}

# - public_ip_address #
function public_ip_address {
    $public_url = 'http://v4.ipv6-test.com/api/myip.php'
    (Invoke-WebRequest -Uri $public_url).Content
}

# - external_ip_address #
function external_ip_address {
    $Params = @{
        ClassName = 'Win32_NetworkAdapterConfiguration'
        Property  = @('DefaultIPGateway', 'IPAddress')
        'Filter'  = 'IPEnabled = 1'
    }

    $interfaces = Get-CimInstance @Params

    foreach ($interface in $interfaces) {
        if ($interface.DefaultIPGateway) {
            $interface.IPAddress[0]
            break
        }
    }
}

# - log #
function log($Level, $Message) {
    $loglevel = @{CRITICAL = 50; ERROR = 40; WARNING = 30; INFO = 20; DEBUG = 10}

    if ($loglevel[$Level] -ge $loglevel[$verbosity]) {
        Write-Output -InputObject "${Level}: $Message"
    }
}

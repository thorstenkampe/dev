# SimplySQL - https://github.com/mithrandyr/simplysql

. $PSScriptRoot/toolbox.ps1

$open_conn = @{
        ms   = 'Open-SqlConnection'
        my   = 'Open-MySqlConnection'
        ora  = 'Open-OracleConnection'
        post = 'Open-PostGreConnection'
}

# DSNs
# use like `$mydsn = $dsn.postlocal; Open-PostGreConnection @mydsn`
$dsn       = [ordered]@{
    mslocal     = [ordered]@{ConnectionName='mslocal'; Server='(localdb)\MSSQLLocalDB'; InitialCatalog='chinook'}
    mslinux     = [ordered]@{ConnectionName='mslinux'; Server='db'; InitialCatalog='chinook'; UserName='sa'; Password='password'}
    mswindows   = [ordered]@{ConnectionName='mswindows'; Server='windows-db'; InitialCatalog='chinook'; UserName='sa'; Password='password'}

    mylocal     = [ordered]@{ConnectionName='mylocal'; Server='rednails'; Database='chinook'; UserName='root'; Password='password'}
    mylinux     = [ordered]@{ConnectionName='mylinux'; Server='db'; UserName='root'; Password='password'}
    mywindows   = [ordered]@{ConnectionName='mywindows'; Server='windows-db'; Database='chinook'; UserName='root'; Password='password'}

    # https://www.nuget.org/packages/Oracle.ManagedDataAccess.Core
    oralinux    = [ordered]@{ConnectionName='oralinux'; DataSource='db'; ServiceName='xe'; UserName='sys'; Password='password'}
    orawindows  = [ordered]@{ConnectionName='orawindows'; DataSource='windows-db'; ServiceName='xepdb1'; UserName='sys'; Password='password'}

    postlocal   = [ordered]@{ConnectionName='postlocal'; Server='rednails'; UserName='postgres'; Password='password'}
    postlinux   = [ordered]@{ConnectionName='postlinux'; Server='db'; UserName='postgres'; Password='password'}
    postwindows = [ordered]@{ConnectionName='postwindows'; Server='windows-db'; UserName='postgres'; Password='password'}

    litelocal   = [ordered]@{ConnectionName='litelocal'; DataSource='F:\cygwin\home\thorsten\data\Chinook.sqlite'}
}

#
function Get-ConnectionPrefix($dsn) {
    foreach ($prefix in 'ms', 'my', 'ora', 'post', 'lite') {
        if ($dsn.ConnectionName.StartsWith($prefix)) {
            $prefix
            break
        }
    }
}

function Engine($dsn) {
    $params = @{
        my   = @{SSLMode='Required'}
        post = @{TrustSSL=$true}
    }

    if ($dsn['UserName'] -eq 'sys') {
        $params.ora = @{DBAPrivilege='sysdba'}
    }

    tb_dupdate $dsn $params[(Get-ConnectionPrefix $dsn)]
}

function Test-DbConnection($dsn) {
    $default_port = @{ms = 1433; my = 3306; ora  = 1521; post = 5432}

    $server = $dsn['Server']
    $port   = $dsn['Port']

    # Oracle
    if (-not $server) {
        $server = $dsn['DataSource']
    }
    # MSSQL
    elseif ($server.Contains(',')) {
        $server, $port = $server -split ','
    }

    if (-not $port) {
        try {
            $port = $default_port[(Get-ConnectionPrefix $dsn)]
        }
        catch [Management.Automation.PropertyNotFoundException] {
        }
    }

    if ($server.ToLower() -in '(localdb)\mssqllocaldb') {
        # we can't test LocalDB
        $true
    }
    else {
        tb_port_reachable -Server $server -Port $port
    }
}

foreach ($cmdlet in 'Sql', 'MySql', 'Oracle', 'PostGre') {
    $PSDefaultParameterValues[('Open-{0}Connection:WarningAction' -f $cmdlet)] = 'Ignore'
}

foreach ($key in $dsn.Keys) {
    Engine $dsn.$key
}

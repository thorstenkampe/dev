# SimplySQL - https://github.com/mithrandyr/simplysql

. $PSScriptRoot/toolbox.ps1

#  - open_conn #
$open_conn = @{
        ms   = 'Open-SqlConnection'
        my   = 'Open-MySqlConnection'
        ora  = 'Open-OracleConnection'
        post = 'Open-PostGreConnection'
}

#  - Get-ConnectionPrefix #
function Get-ConnectionPrefix($dsn) {
    foreach ($prefix in 'ms', 'my', 'ora', 'post', 'lite') {
        if ($dsn.ConnectionName.StartsWith($prefix)) {
            $prefix
            break
        }
    }
}

#  - Engine #
function Engine($dsn) {
    $params = @{
        my   = @{SSLMode='Required'}
        post = @{TrustSSL=$true}
    }

    if ($dsn['UserName'] -eq 'sys') {
        $params.ora = @{DBAPrivilege='sysdba'}
    }

    dupdate $dsn $params[(Get-ConnectionPrefix $dsn)]
}

#  - Test-DbConnection #
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
        Test-Connection -TargetName $server -TcpPort $port -TimeoutSeconds 1 -Quiet
    }
}

foreach ($cmdlet in 'Sql', 'MySql', 'Oracle', 'PostGre') {
    $PSDefaultParameterValues[('Open-{0}Connection:WarningAction' -f $cmdlet)] = 'Ignore'
}

Import-Module -Name PesterMatchHashtable

BeforeAll {
    . $PSScriptRoot/../tb_sql.ps1

    function Get-TypeName($object) {
        $object.GetType().Name
    }
}

# Get-ConnectionPrefix
Describe 'Get-ConnectionPrefix' {
    It 'PostgreSQL' {
        Assert-Equal -Actual (Get-ConnectionPrefix @{ConnectionName='postlocal'}) -Expected 'post'
    }
}

# Engine
Describe 'Engine' {
    It 'MySQL' {
        $dsn = @{ConnectionName='my'}
        Engine $dsn
        $dsn | Should -MatchHashtable @{ConnectionName='my'; SSLMode='Required'}
    }

    It 'Oracle' {
        $dsn = @{ConnectionName='ora'; UserName='sys'}
        Engine $dsn
        $result = @{ConnectionName='ora'; UserName='sys'; DBAPrivilege='sysdba'}
        $dsn | Should -MatchHashtable $result
    }

    It 'PostgreSQL' {
        $dsn = @{ConnectionName='post'}
        Engine $dsn
        $result = @{ConnectionName='post'; TrustSSL=$true}
        $dsn | Should -MatchHashtable $result
    }

    It 'SQLite' {
        $dsn = @{ConnectionName='lite'; DataSource=':memory:'}
        Engine $dsn
        $dsn | Should -MatchHashtable @{ConnectionName='lite'; DataSource=':memory:'}
    }
}

# Test-DbConnection
Describe 'Test-DbConnection' {
    It 'MSSQL LocalDB' {
        $dsn = @{ConnectionName='ms'; Server='(localdb)\MSSQLLocalDB'}
        Assert-Equal -Actual (Test-DbConnection $dsn) -Expected $true
    }
}

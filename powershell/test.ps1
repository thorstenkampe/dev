[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
Param()

. $PSScriptRoot/tb_sql.ps1

# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_arrays
$array     = 1, 2, 3, 4, 5, 6, 7, 8, 'i'

# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables
# ordered hashtables can be accessed via key as well as numerical index
$ordered   = [ordered]@{a=1; b=2; c=3; d=4; e=5; f=6; g=7; h=8; '9'='i'}
$hashtable =          @{a=1; b=2; c=3; d=4; e=5; f=6; g=7; h=8; '9'='i'}

$string    = 'The quick brown fox jumps over the lazy dog'

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

foreach ($key in $dsn.Keys) {
    Engine $dsn.$key
}

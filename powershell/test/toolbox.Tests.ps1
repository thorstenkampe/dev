Import-Module -Name PesterMatchArray
Import-Module -Name PesterMatchHashtable

. $PSScriptRoot/../toolbox.ps1

BeforeAll {
    . $PSScriptRoot/../toolbox.ps1

    function Get-TypeName($object) {
        $object.GetType().Name
    }
}

# tb_map
Describe 'tb_map' {
    BeforeEach {
        . $PSScriptRoot/../test.ps1
    }

    It 'array' {
        $result = 'Int32', 'Int32', 'Int32', 'Int32', 'Int32', 'Int32', 'Int32', 'Int32', 'String'

        tb_map -Keyfunc Get-TypeName $array
        ,$array | Should -MatchArrayOrdered $result
    }

    It 'hashtable' {
        $result = @{a='Int32'; b='Int32'; c='Int32'; d='Int32'; e='Int32'; f='Int32'; g='Int32'; h='Int32'; '9'='String'}

        tb_map -Keyfunc Get-TypeName $hashtable
        $hashtable | Should -MatchHashtable $result
    }
}

# tb_dupdate
Describe 'tb_dupdate' {
    BeforeEach {
        . $PSScriptRoot/../test.ps1
    }

    It 'tb_dupdate' {
        $result = @{a=1; b=2; c=3; d=4; e=5; f=6; g=7; h=8; i=9; '9'='j'}

        tb_dupdate $hashtable @{i=9; '9'='j'}
        $hashtable | Should -MatchHashtable $result
    }
}

# tb_exec
Describe 'tb_exec' {
    It 'no error' {
        tb_exec -Cmd true
    }

    It 'error' {
        $exception = 'Command terminated with exit code 1'
        {tb_exec -Cmd false} | Should -Throw -ExpectedMessage $exception
    }
}

# tb_groupby
# PowerShell Desktop would need `-AsString` for `Group-Object` in `tb_groupby`
if (tb_is_pscore) {
    Describe 'tb_groupby' {
        BeforeEach {
            . $PSScriptRoot/../test.ps1
        }

        It 'array' {
            $grouped = tb_groupby -keyfunc Get-TypeName $array

            $grouped['Int32']  | Should -Be 1, 2, 3, 4, 5, 6, 7, 8
            $grouped['String'] | Should -Be 'i'
        }

        It 'hashtable' {
            $grouped = tb_groupby -keyfunc {param($x) Get-TypeName $x.Value} $ordered

            $grouped['Int32'].Name   | Should -Be 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'
            $grouped['Int32'].Value  | Should -Be 1, 2, 3, 4, 5, 6, 7, 8
            $grouped['String'].Name  | Should -Be 9
            $grouped['String'].Value | Should -Be 'i'
        }
    }
}

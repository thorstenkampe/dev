Import-Module -Name PesterMatchArray
Import-Module -Name PesterMatchHashtable

. $PSScriptRoot/../toolbox.ps1

BeforeAll {
    $ErrorActionPreference = 'Stop'
    Set-StrictMode -Version latest

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
        $result = 'Int32', 'Int32', 'Int32', 'Int32', 'Int32', 'Int32', 'String', 'String', 'String'

        tb_map -Keyfunc Get-TypeName $test_array
        ,$test_array | Should -MatchArrayOrdered $result
    }

    It 'hashtable' {
        $result = @{a='Int32'; b='Int32'; c='Int32'; d='Int32'; e='Int32'; f='Int32'; g='String'; 'h h'='String'; 9='String'}

        tb_map -Keyfunc Get-TypeName $test_hashtable
        $test_hashtable | Should -MatchHashtable $result
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
Describe 'tb_groupby' {
    BeforeEach {
        . $PSScriptRoot/../test.ps1
    }

    It 'array' {
        $grouped = tb_groupby -keyfunc Get-TypeName $test_array

        $grouped['Int32']  | Should -Be 1, 2, 3, 4, 5, 6
        $grouped['String'] | Should -Be '7', '8 8', ''
    }

    It 'hashtable' {
        $grouped = tb_groupby -keyfunc {param($x) Get-TypeName $x.Value} $test_ordered

        $grouped['Int32'].Name   | Should -Be 'a', 'b', 'c', 'd', 'e', 'f'
        $grouped['Int32'].Value  | Should -Be 1, 2, 3, 4, 5, 6
        $grouped['String'].Name  | Should -Be 'g', 'h h', 9
        $grouped['String'].Value | Should -Be '7', '8 8', ''
    }

    It 'case sensitive' {
        $grouped = tb_groupby {param($x) $x} 'a', 'A'

        if (tb_is_pscore) {
            $grouped['A'] | Should -Be 'A'
            $grouped['a'] | Should -Be 'a'
        }
        else {
            $grouped['A'] | Should -Be 'a', 'A'
            $grouped['a'] | Should -Be 'a', 'A'
        }
    }
}

Import-Module -Name PesterMatchHashtable

BeforeAll {
    . $PSScriptRoot/../toolbox.ps1

    function Get-TypeName($object) {
        $object.GetType().Name
    }
}

# dmap
Describe 'dmap' {
    BeforeEach {
        . $PSScriptRoot/../test.ps1
    }

    It 'dmap' {
        $result = @{a='Int32'; b='Int32'; c='Int32'; d='Int32'; e='Int32'; f='Int32'; g='Int32'; h='Int32'; '9'='String'}

        dmap $hashtable -Keyfunc Get-TypeName
        $hashtable | Should -MatchHashtable $result
    }
}

# dupdate
Describe 'dupdate' {
    BeforeEach {
        . $PSScriptRoot/../test.ps1
    }

    It 'dupdate' {
        $result = @{a=1; b=2; c=3; d=4; e=5; f=6; g=7; h=8; i=9; '9'='j'}

        dupdate $hashtable @{i=9; '9'='j'}
        $hashtable | Should -MatchHashtable $result
    }
}

# groupby
Describe 'groupby' {
    BeforeEach {
        . $PSScriptRoot/../test.ps1
    }

    It 'array' {
        $grouped = groupby $array -keyfunc Get-TypeName

        $grouped['Int32']  | Should -Be 1, 2, 3, 4, 5, 6, 7, 8
        $grouped['String'] | Should -Be 'i'
    }

    It 'hashtable' {
        $grouped = groupby $ordered -keyfunc {param($x) Get-TypeName $x.Value}

        $grouped['Int32'].Name   | Should -Be 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'
        $grouped['Int32'].Value  | Should -Be 1, 2, 3, 4, 5, 6, 7, 8
        $grouped['String'].Name  | Should -Be 9
        $grouped['String'].Value | Should -Be 'i'
    }
}

# log
Describe 'log' {
    It 'info message' {
        $verbosity = 'WARNING'
        $result = log INFO 'test message'

        Assert-Equal -Actual $result -Expected $null
    }

    It 'verbosity info message' {
        $verbosity = 'INFO'
        $result    = log INFO 'test message'
        $expected  ='INFO: test message'

        Assert-Equal -Actual $result -Expected $expected
    }
}

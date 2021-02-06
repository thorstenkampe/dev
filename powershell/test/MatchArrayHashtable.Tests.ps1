Import-Module -Name PesterMatchArray
Import-Module -Name PesterMatchHashtable

Describe 'MatchArrayOrdered examples' {
	It 'single item arrays match' {
        ,@('a')    | Should -MatchArrayOrdered 'a'
    }

    It 'arrays with the same contents match' {
        ,@('a', 1) | Should -MatchArrayOrdered 'a', 1
    }

    It 'arrays with the same contents in different orders do not match' {
        ,@('a', 1) | Should -Not -MatchArrayOrdered 1, 'a'
    }
}

Describe 'MatchArrayUnordered examples' {
	It 'single item arrays match' {
        ,@('a')    | Should -MatchArrayUnordered 'a'
    }

    It 'arrays with the same contents match' {
        ,@('a', 1) | Should -MatchArrayUnordered 'a', 1
    }

    It 'arrays with the same contents in different orders match' {
        ,@('a', 1) | Should -MatchArrayUnordered 1, 'a'
    }
}

Describe 'MatchHashtable examples' {
	It 'single item hashtables match' {
        @{a=1}             | Should -MatchHashtable @{a=1}
    }

    It 'hashtables with the same contents match' {
        @{a=1; b='wibble'} | Should -MatchHashtable @{b='wibble'; a=1}
    }

    It 'hashtables with different lengths do not match' {
        @{a=1}             | Should -Not -MatchHashtable @{b='wibble'; a=1}
    }

    It 'hashtables with different lengths do not match' {
        @{a=1; b='wibble'} | Should -Not -MatchHashtable @{b='wibble'}
    }

    It 'hashtables with different values do not match' {
        @{a=1; b='wibble'} | Should -Not -MatchHashtable @{a=123; b='wibble'}
    }
}

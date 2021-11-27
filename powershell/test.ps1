# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_arrays
# arrays can use commas (`1, ...`, `@(1, ...)`) and semicolons (`@(1; ...)`), semicolons
# only within `@()`
$array     = 1, 2, 3, 4, 5, 6, 7, 8, 'i'

# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables
# hashtables can only use semicolons (`@{1; ...}`)
# ordered hashtables can be accessed via key as well as numerical index
$ordered   = [ordered]@{a=1; b=2; c=3; d=4; e=5; f=6; g=7; h=8; '9'='i'}
$hashtable =          @{a=1; b=2; c=3; d=4; e=5; f=6; g=7; h=8; '9'='i'}

$string    = 'The quick brown fox jumps over the lazy dog'

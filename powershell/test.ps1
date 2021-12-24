# * https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_arrays
# * arrays can use commas (`1, ...`, `@(1, ...)`) and semicolons (`@(1; ...)`),
#   semicolons only within `@()`
# * .clone() an array is shallow
$array     = 1, 2, 3, 4, 5, 6, '7', '8 8', ''

# * https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables
# * hashtables can only use semicolons (`@{a=1; ...}`)
# * .clone() a hash is shallow. Copying hashes with "(foreach key {clone[key] = orig[key]})"
#   is also shallow
$hashtable =          @{a=1; b=2; c=3; d=4; e=5; f=6; 'g'='7'; 'h h'='8 8'; 9=''}

# * .clone() an ordered dictionary is not supported
# * ordered dictionaries can be accessed via key as well as numerical index; key
#   must not be integer (`[ordered]@{1=...}`), otherwise it can't be accessed (`$ordered[1]`)
$ordered   = [ordered]@{a=1; b=2; c=3; d=4; e=5; f=6; 'g'='7'; 'h h'='8 8'; 9=''}

$string    = 'The quick brown fox jumps over the lazy dog'

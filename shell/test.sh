# shellcheck disable=SC2034

string='The quick brown fox jumps over the lazy dog'

declare -gi int
int=123

# https://mywiki.wooledge.org/BashGuide/Arrays
# show all: `declare -p array`
array=(1 2 3 4 5 6 7 8 '')

# show all: `declare -p assoc`
declare -gA assoc=([a]=1 [b]=2 [c]=3 [d]=4 [e]=5 [f]=6 [g]=7 [h]=8 [9]='')

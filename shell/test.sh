# shellcheck disable=SC2034

string='The quick brown fox jumps over the lazy dog'

# https://mywiki.wooledge.org/BashGuide/Arrays
array=(1 2 3 4 5 6 7 8 9)  # show all: echo ${array[@]}

declare -gA assoc
# show all: declare -p assoc
assoc=([a]=1 [b]=2 [c]=3 [d]=4 [e]=5 [f]=6 [g]=7 [h]=8 [9]=9)

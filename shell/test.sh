# shellcheck disable=SC2034

test_string='The quick brown fox jumps over the lazy dog'

declare -gi test_int=123

# https://mywiki.wooledge.org/BashGuide/Arrays
# show array elements: `declare -p test_array`
test_array=( [0]=1 [1]=2 [2]=3 [3]=4 [4]=5 [5]=6 [6]=7 [7]='8 8' [9]='' )  # this is a sparse array (no `${array[8]}`)

# show array elements: `declare -p test_assoc`
declare -gA test_assoc=( [a]=1 [b]=2 [c]=3 [d]=4 [e]=5 [f]=6 [g]=7 [h h]='8 8' [9]='' )

declare -gn test_nameref=test_assoc

#
function test_vartype {
    case $(declare -p "$1" 2> /dev/null) in
        (declare\ -a*)
            echo 'indexed array'
            ;;

        (declare\ -A*)
            echo 'associative array'
            ;;

        (declare\ -i*)
            echo integer
            ;;

        (declare\ -n*)
            echo 'name reference'
            ;;

        (declare\ --*)
            echo string
            ;;

        ('')
            echo 'not set'
            ;;

        (*)
            echo unknown
            return 1
    esac
}

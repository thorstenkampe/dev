# HELP #
help='Usage: script.sh'

# INITIALIZATION #
PS4='+$(basename $BASH_SOURCE)${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
shopt -os nounset pipefail errexit
IFS=''                   # disable word splitting
export LANG=en_US.UTF-8  # neutral environment

# LOGGING #
[[ -o xtrace ]] && verbosity=DEBUG || verbosity=WARNING
declare -A loglevel=([CRITICAL]=50 [ERROR]=40 [WARNING]=30 [INFO]=20 [DEBUG]=10) \
           colorcode=([CRITICAL]='1;31' [ERROR]=31 [WARNING]=33 [INFO]=32 [DEBUG]='')

function log {
    if ((loglevel[$1] >= loglevel[$verbosity]))
    then
        printf '\e[%sm%s\e[m: %s\n' "${colorcode[$1]}" "$1" "$2" >&2
    fi
}

# DEFAULT OPTIONS #
while getopts h option
do
    case $option in
        (h)
            echo "$help"
            exit;;

        ('?')
            exit 1
    esac
done
shift $((OPTIND - 1))  # remove options from command line

# MAIN CODE STARTS HERE #

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
        echo -e "\e[${colorcode[$1]}m$1\e[m: $2" >&2
    fi
}

# MAIN CODE STARTS HERE #

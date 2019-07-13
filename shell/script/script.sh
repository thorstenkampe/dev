# INITIALIZATION #
PS4='+$(basename $BASH_SOURCE)${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
shopt -os nounset pipefail errexit
IFS=                     # disable word splitting
export LANG=en_US.UTF-8  # neutral environment

# LOGGING #
[[ -o xtrace ]] && verbosity=DEBUG || verbosity=WARNING
declare -A loglevel colorcodes
loglevel=([CRITICAL]=50 [ERROR]=40 [WARNING]=30 [INFO]=20 [DEBUG]=10)
colorcodes=([CRITICAL]='1;31' [ERROR]='0;31' [WARNING]='0;33' [INFO]='0;32' [DEBUG]='0;37')

function log {
    if ((loglevel[$1] >= loglevel[$verbosity]))
    then
        if [[ -t 2 ]]  # only output color if stderr is attached to tty
        then
            echo -e "\e[${colorcodes[$1]}m$1\e[m: $2"
        else
            echo "$1: $2"
        fi > /dev/stderr
    fi
}

# MAIN CODE STARTS HERE #

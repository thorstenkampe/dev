# INITIALIZATION #
PS4='+$(basename $BASH_SOURCE)${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
shopt -os nounset pipefail errexit
IFS=''                   # disable word splitting
export LANG=en_US.UTF-8  # neutral environment

# LOGGING #
[[ -o xtrace ]] && verbosity=DEBUG || verbosity=WARNING
declare -A loglevel=([CRITICAL]=50 [ERROR]=40 [WARNING]=30 [INFO]=20 [DEBUG]=10) \
           color=([CRITICAL]='\e[1;31m' [ERROR]='\e[0;31m' [WARNING]='\e[0;33m' [INFO]='\e[0;32m' [DEBUG]='\e[0;37m' [RESET]='\e[m')
# no color if stderr is not attached to tty
[[ ! -t 2 ]] && color=([CRITICAL]='' [ERROR]='' [WARNING]='' [INFO]='' [DEBUG]='' [RESET]='')

function log {
    if ((loglevel[$1] >= loglevel[$verbosity]))
    then
        echo -e "${color[$1]}$1${color[RESET]}: $2" > /dev/stderr
    fi
}

# MAIN CODE STARTS HERE #

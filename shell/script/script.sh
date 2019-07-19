# INITIALIZATION #
PS4='+$(basename $BASH_SOURCE)${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
shopt -os nounset pipefail errexit
IFS=''                   # disable word splitting
export LANG=en_US.UTF-8  # neutral environment
# * color codes: http://en.wikipedia.org/wiki/ANSI_escape_code#Colors
# * use `ansifilter` to discard color codes when redirecting to file
declare -A colorcode=([red]='\e[31m' [green]='\e[32m' [yellow]='\e[33m' [white]='\e[37m'
                      [brightred]='\e[1;31m' [reset]='\e[m')

# LOGGING #
if [[ -o xtrace ]]
then
    verbosity=DEBUG
else
    verbosity=WARNING
fi

declare -A loglevel=([CRITICAL]=50 [ERROR]=40 [WARNING]=30 [INFO]=20 [DEBUG]=10) \
           color=([CRITICAL]=brightred [ERROR]=red [WARNING]=yellow [INFO]=green [DEBUG]=white)

function log {
    if ((loglevel[$1] >= loglevel[$verbosity]))
    then
        echo -e "${colorcode[${color[$1]}]}$1${colorcode[reset]}: $2" >&2
    fi
}

# MAIN CODE STARTS HERE #

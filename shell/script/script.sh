# INITIALIZATION #
PS4='+$(basename $BASH_SOURCE)${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
shopt -os nounset pipefail errexit
IFS=                     # disable word splitting
export LANG=en_US.UTF-8  # neutral environment

# LOGGING #
if [[ -o xtrace ]]
then
    verbosity=DEBUG
else
    verbosity=WARNING
fi
declare -A loglevel colorcodes
loglevel=([CRITICAL]=50 [ERROR]=40 [WARNING]=30 [INFO]=20 [DEBUG]=10)
if [[ -t 2 ]]  # only output color if stderr is attached to tty
then
    colorcodes=([CRITICAL]='\e[1;31m' [ERROR]='\e[0;31m' [WARNING]='\e[0;33m' [INFO]='\e[0;32m'
                [DEBUG]='\e[0;37m' [RESET]='\e[m')
else
    colorcodes=([CRITICAL]= [ERROR]= [WARNING]= [INFO]= [DEBUG]= [RESET]=)
fi

function log {
    if ((loglevel[$1] >= loglevel[$verbosity]))
    then
        echo -e "${colorcodes[$1]}$1${colorcodes[RESET]}: $2" > /dev/stderr
    fi
}

# MAIN CODE STARTS HERE #

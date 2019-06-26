# shellcheck shell=bash

## INITIALIZATION ##
IFS=  # disable word splitting

shopt -os nounset pipefail errexit

## LOGGING ##
declare -A loglevel color

verbosity=WARNING  # default level

# * Modeled after Python modules `logging` and `colorlog`
# * For color codes see http://en.wikipedia.org/wiki/ANSI_escape_code#Colors
loglevel[CRITICAL]=10  color[CRITICAL]=$'\e[1;31m'  # brightred
loglevel[ERROR]=20     color[ERROR]=$'\e[0;31m'     # red
loglevel[WARNING]=30   color[WARNING]=$'\e[0;33m'   # yellow
loglevel[INFO]=40      color[INFO]=$'\e[0;32m'      # green
loglevel[DEBUG]=50     color[DEBUG]=$'\e[0;37m'     # white

function log {
    if ((${loglevel[$1]} <= ${loglevel[$verbosity]}))
    then
        if [[ -t 2 ]]  # only output color if stderr is attached to tty
        then
            printf '%s%s\e[m: %s\n' ${color[$1]} "$1" "$2"
        else
            printf '%s: %s\n' "$1" "$2"
        fi > /dev/stderr
    fi
}

## HELP ##
# leading `:`: don't report unknown options (which we can't know in advance here)
if getopts :h option
then
    if [[ $option == h ]]
    then
        # shellcheck disable=SC2154
        printf '%s' "$help"
        exit
    fi
fi
OPTIND=1  # reset `OPTIND` for the next round of parsing

## TRAPS ##
# create your own handler in the main script

# this will run when program exits abnormally
function error_handler {
    error_code=$?
    printf '\n'
    log ERROR "received $1 signal, exiting..."
    exit $error_code
}

# This will always run (after the error handler)
function exit_handler {
    :
}

for signal in ERR INT HUP QUIT TERM
do
    # shellcheck disable=SC2064
    trap "error_handler $signal" $signal
done

trap exit_handler EXIT

## DEBUGGING ##
PS4='+$(basename $BASH_SOURCE)${FUNCNAME:+:$FUNCNAME}[$LINENO]: '

# leading `:`: don't report unknown options (which we can't know in advance here)
if getopts :d option
then
    if [[ $option == d ]]
    then
        verbosity=DEBUG
        log DEBUG "bash $BASH_VERSION"
        # * https://www.gnu.org/software/gettext/manual/html_node/Locale-Environment-Variables.html
        # * http://pubs.opengroup.org/onlinepubs/7908799/xbd/locale.html
        log DEBUG "LANGUAGE: ${LANGUAGE-} LC_ALL: ${LC_ALL-} LANG: ${LANG-} decimal point: $(locale decimal_point)"

        set -o xtrace
    fi
fi
OPTIND=1  # reset `OPTIND` for the next round of parsing in main script

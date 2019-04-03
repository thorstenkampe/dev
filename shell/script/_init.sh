## * short instead of long options are used for macOS compatibility
## * we use `>&2` instead of `> /dev/stderr` because of problems with the
##   implementation on Cygwin

## INITIALIZATION ##
IFS=  # disable word splitting

shopt -os nounset pipefail

## INTERNATIONALIZATION ##
# http://www.gnu.org/software/gettext/manual/gettext.html#Preparing-Shell-Scripts
export TEXTDOMAIN=$(basename $script) \
       TEXTDOMAINDIR=$(dirname $script)/_translations

if ! which gettext &> /dev/null
then
    function gettext {
        printf '%s' "$@"
    }
fi

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
            printf '%s%s\e[m: %s\n' ${color[$1]} $1 $2 >&2
        else
            printf '%s: %s\n' $1 $2 >&2
        fi
    fi
}

## STANDARD OPTIONS ##
# leading `:`: don't report unknown options (which we can't know in advance here)
getopts :h option
if [[ $option == h ]]
then
    gettext $help
    exit
fi
OPTIND=1  # reset `OPTIND` for the next round of parsing in main script

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
    trap "error_handler $signal" $signal
done

trap exit_handler EXIT

## DEBUGGING ##
PS4='+$(basename $BASH_SOURCE)${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
shell_version=$(printf '%s.%s.%s' ${BASH_VERSINFO[@]:0:3})

if [[ -v DEBUG ]]
then
    verbosity=DEBUG
    log DEBUG "bash $shell_version"
    # https://www.gnu.org/software/gettext/manual/html_node/Locale-Environment-Variables.html
    # http://pubs.opengroup.org/onlinepubs/7908799/xbd/locale.html
    log DEBUG "LANGUAGE: ${LANGUAGE-}"
    log DEBUG "LC_ALL: ${LC_ALL-}"
    log DEBUG "LANG: ${LANG-}"
    log DEBUG "decimal point: $(locale decimal_point)"

    set -o xtrace
fi

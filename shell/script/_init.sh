## - short instead of long options are used for macOS compatibility
## - we don't use `> /dev/stderr` instead of `>&2` because of problems
##   with the implementation on Cygwin

## INITIALIZATION ##
if [[ $OSTYPE == cygwin ]]
then
    # `ps` is `procps` on Cygwin
    ps() { procps "$@"; }
fi

shell=$(ps -p $$ -o comm=)

IFS=  # disable word splitting

set -o nounset \
    -o pipefail

## INTERNATIONALIZATION ##
# http://www.gnu.org/software/gettext/manual/gettext.html#sh
export TEXTDOMAIN=$(basename $script) \
       TEXTDOMAINDIR=$(dirname $script)/_translations

if ! which gettext &> /dev/null
then
    # http://zshwiki.org/home/scripting/args
    gettext() { printf "%s" "$@"; }
fi

## LOGGING ##
if [[ $shell == bash ]] && ((BASH_VERSINFO <= 3))
then
    # No associative arrays in Bash 3, so only rudimentary logging
    log() { printf "%s: %s\n" $1 $2 >&2; }
else
    declare -A loglevel color

    # Modeled after Python modules `logging` and `colorlog`
    verbosity=WARNING  # default level

    # For color codes see http://en.wikipedia.org/wiki/ANSI_escape_code#Colors
    loglevel[CRITICAL]=10  color[CRITICAL]=$'\e[1;31m'  # brightred
    loglevel[ERROR]=20     color[ERROR]=$'\e[0;31m'     # red
    loglevel[WARNING]=30   color[WARNING]=$'\e[0;33m'   # yellow
    loglevel[INFO]=40      color[INFO]=$'\e[0;32m'      # green
    loglevel[DEBUG]=50     color[DEBUG]=$'\e[0;37m'     # white

    reset=$'\e[m'

    log() {
        if ((${loglevel[$1]} <= ${loglevel[$verbosity]}))
        then
            # only output color if stderr is attached to tty
            if [[ -t 2 ]]
            then
                printf "%s%s:%s %s\n" ${color[$1]} $1 $reset $2 >&2
            else
                printf "%s: %s\n" $1 $2 >&2
            fi
        fi
    }
fi

## STANDARD OPTIONS ##
# leading `:`: don't report unknown options (which we can't know in
# advance here)
while getopts :h option
do
    if [[ $option == h ]]
    then
        gettext $help
        exit
    fi
done
# reset `OPTIND` for the next round of parsing in main script
OPTIND=1

## TRAPS ##
# - create your own handler in the main script
# - bash and zsh run traps when child process exits (option `trapsasync`
#   in zsh)

# will also run on error (except with zsh on Linux)
exit_handler() { :; }

error_handler() {
    error_code=$?
    exit $error_code
}

trap exit_handler EXIT
trap error_handler ERR INT HUP QUIT TERM

## DEBUGGING ##
if [[ -n ${DEBUG-} ]]
then
    if [[ $shell == bash ]]
    then
        PS4='$(printf "+%s%s[%s]: " \
            $(basename $BASH_SOURCE) "${FUNCNAME:+:$FUNCNAME}" $LINENO)'
        shell_version=$(printf "%s.%s.%s" ${BASH_VERSINFO[@]:0:3})
    else
        PS4='+%1N[%I]: '
        shell_version=$ZSH_VERSION
    fi

    verbosity=DEBUG
    log DEBUG $(printf "%s %s" $shell $shell_version)

    # https://www.gnu.org/software/gettext/manual/html_node/Locale-Environment-Variables.html
    # http://pubs.opengroup.org/onlinepubs/7908799/xbd/locale.html
    log DEBUG $(printf 'LANGUAGE: "%s", LC_ALL: "%s", LANG: "%s", decimal point: "%s"' \
                "${LANGUAGE-}" "${LC_ALL-}" "${LANG-}" $(locale decimal_point))

    set -o xtrace
fi

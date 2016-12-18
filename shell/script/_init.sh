## - short instead of long options are used for OS X compatibility
## - we don't use `> /dev/stderr` instead of `>&2` because of problems
##   with the implementation on Cygwin

## VARIABLES ##
IFS=  # disable word splitting

# functions mostly used for debugging shouldn't run on normal execution
isCygwin() { [[ $OSTYPE == cygwin ]]; }
isLinux()  { [[ $OSTYPE == linux-gnu ]]; }
isOSX()    { [[ $OSTYPE =~ ^darwin ]]; }
isUbuntu() { [[ -e /etc/lsb-release ]]; }
isRedHat() { [[ -e /etc/redhat-release ]]; }
isSUSE()   { [[ -e /etc/SuSE-release ]]; }

if isCygwin  # `ps` is `procps` on Cygwin
then
    shell=$(procps --pid $$ --format comm=)
else
    # `ps` shows full path on OS X
    shell=$(basename $(ps -p $$ -o comm=))
fi

isBash()  { [[ $shell == bash ]]; }
isBash3() { isBash && ((BASH_VERSINFO <= 3)); }

if isBash
then
    PS4='$(printf "+%s%s[%s]: " \
           $(basename $BASH_SOURCE) "${FUNCNAME:+:$FUNCNAME}" $LINENO)'
else
    PS4='+%1N[%I]: '
fi

## SHELL OPTIONS ##
# stop when an error occurs
set -o nounset \
    -o pipefail

## INTERNATIONALIZATION ##
# http://www.gnu.org/software/gettext/manual/gettext.html#sh
export TEXTDOMAIN=$(basename $script) \
       TEXTDOMAINDIR=$(dirname $script)/_translations

if ! which gettext &> /dev/null
then
    gettext() {
        # http://zshwiki.org/home/scripting/args
        printf "%s" "$@"
    }
fi

## LOGGING ##
if isBash3
then
    # No associative arrays in Bash 3, so only rudimentary logging
    log() {
        printf "%s: %s\n" $1 $2 >&2
    }
else
    declare -A loglevel color

    # Modeled after Python modules `logging` and `colorlog`
    verbosity=WARNING  # default level

    # For color codes see http://en.wikipedia.org/wiki/ANSI_escape_code#Colors
    loglevel[CRITICAL]=10 ; color[CRITICAL]=$'\e[1;31m'  # brightred
    loglevel[ERROR]=20    ; color[ERROR]=$'\e[0;31m'     # red
    loglevel[WARNING]=30  ; color[WARNING]=$'\e[0;33m'   # yellow
    loglevel[INFO]=40     ; color[INFO]=$'\e[0;32m'      # green
    loglevel[DEBUG]=50    ; color[DEBUG]=$'\e[0;37m'     # white

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

## VERSION ##
shell_version() {
    if isBash
    then
        printf "%s.%s.%s" ${BASH_VERSINFO[@]:0:3}
    else
        printf "%s" $ZSH_VERSION
    fi
}

os_version() {
    if   isCygwin
    then
        osver=$(uname --kernel-release)
        printf "Cygwin %s" ${osver%\(*}

    elif isOSX
    then
        printf "OS X %s" \
        $(python -c 'import platform; print(platform.mac_ver()[0])')

    elif isUbuntu
    then
        source /etc/lsb-release
        printf "%s" $DISTRIB_DESCRIPTION

    # RHEL, XENSERVER
    elif isRedHat
    then
        awk '
{NF--  # print file except last field
 print}' \
            /etc/redhat-release

    # SLES
    elif isSUSE
    then
        awk '
NR == 1 {NF--       # print first line except last field
         printf "%s SP ", $0}
NR == 3 {print $3}  # print third field from third line' \
            /etc/SuSE-release

    # OTHER LINUX DISTRIBUTION
    elif isLinux
    then
        printf "Linux"
    fi
}

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

## SPINNER ##
# taken from http://stackoverflow.com/a/12498305
spinner() {
    # error in background job will not abort script
    eval "$@" &
    spin='-\|/'

    i=0
    while kill -0 $! 2> /dev/null
    do
        printf "\r[%s]" ${spin:$(($((i += 1)) % 4)):1}
        sleep 0.1
    done
    printf "\n"
}

## TRAPS ##
# - create your own handler in the main script
# - bash and zsh run traps when child process exits (option `trapsasync`
#   in zsh)

# will also run on error (except with zsh on Linux)
exit_handler() {
    :
}

error_handler() {
    error_code=$?
    exit $error_code
}

trap exit_handler EXIT
trap error_handler ERR INT HUP QUIT TERM

## DEBUGGING ##
if [[ -n ${DEBUG-} ]]
then
    verbosity=DEBUG
    log DEBUG $(printf "%s %s on %s %s" \
                $shell $(shell_version) $(os_version) $(uname -m))

    # https://www.gnu.org/software/gettext/manual/html_node/Locale-Environment-Variables.html
    # http://pubs.opengroup.org/onlinepubs/7908799/xbd/locale.html
    log DEBUG $(printf 'LANGUAGE: "%s", LC_ALL: "%s", LANG: "%s", decimal point: "%s"' \
                "${LANGUAGE-}" "${LC_ALL-}" "${LANG-}" $(locale decimal_point))

    set -o xtrace
fi

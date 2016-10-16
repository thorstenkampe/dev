IFS=  # disable word splitting
scriptname=$(basename $script)

## short instead of long options are used for OS X compatibility

## VARIABLES ##
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

## SHELL OPTIONS ##
if isBash
then
    shopt -os errexit nounset pipefail  # stop when an error occurs
else
    emulate -R zsh                      # set all options to default
    setopt errexit nounset pipefail     # stop when an error occurs
fi

## INTERNATIONALIZATION ##
# http://www.gnu.org/software/gettext/manual/gettext.html#sh
export TEXTDOMAIN=$scriptname \
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
        printf "%s: %s\n" $1 $2 > /dev/stderr
    }
else
    declare -A loglevel color

    # Modeled after Python modules `logging` and `colorlog`
    verbosity=WARNING  # default level

    # Assigning associative array elements via subscript is the only
    # syntax bash and zsh share
    # For color codes see http://en.wikipedia.org/wiki/ANSI_escape_code#Colors
    loglevel[CRITICAL]=10 ; color[CRITICAL]=$'\e[1;31m'  # brightred
    loglevel[ERROR]=20    ; color[ERROR]=$'\e[0;31m'     # red
    loglevel[WARNING]=30  ; color[WARNING]=$'\e[0;33m'   # yellow
    loglevel[INFO]=40     ; color[INFO]=$'\e[0;32m'      # green
    loglevel[DEBUG]=50    ; color[DEBUG]=$'\e[0;37m'     # white

    log() {
        if ((${loglevel[$1]} <= ${loglevel[$verbosity]}))
        then
            # only output color if stderr is attached to tty
            if [[ -t 2 ]]
            then
                # `> /dev/stderr` is equivalent to `>&2`
                printf "%s%s:\e[m %s\n" ${color[$1]} $1 $2 > /dev/stderr
            else
                printf "%s: %s\n" $1 $2 > /dev/stderr
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
while getopts :dh option
do
    # DEBUG
    if   [[ $option == d ]]
    then
        verbosity=DEBUG

        log DEBUG "$shell $(shell_version) on $(os_version) $(uname -m)"
        # https://www.gnu.org/software/gettext/manual/html_node/Locale-Environment-Variables.html
        # http://pubs.opengroup.org/onlinepubs/7908799/xbd/locale.html
        log DEBUG "LANGUAGE: ${LANGUAGE-}
       LC_ALL: ${LC_ALL-}
       LANG: ${LANG-}
       decimal point: $(locale decimal_point)"
        log DEBUG Trace

        if isBash
        then
            PS4='+$(basename $BASH_SOURCE)${FUNCNAME+:$FUNCNAME}[$LINENO]: '
            shopt -os xtrace
        else
            PS4='+%1N[%I]: '
            setopt xtrace
        fi

    # HELP
    elif [[ $option == h ]]
    then
        gettext "\
\`$scriptname\` $description

Usage:
 $scriptname $usage

Options:$options_help
 -d   show debug messages
 -h   show help
"
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
# create your own cleanup function in the main script
cleanup() {
    return
}

if isBash
then
    trap cleanup EXIT
else
    setopt trapsasync
    trap "cleanup; exit" EXIT INT HUP TERM
fi

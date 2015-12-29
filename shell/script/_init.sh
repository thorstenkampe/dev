_INIT_VERSION='$Revision$'
_INIT_DATE='$Date$'

IFS=  # disable word splitting
scriptname=$(basename $script)

## short instead of long options are used for OS X compatibility

## SHELL ##
if [[ $OSTYPE = cygwin ]]  # `ps` is `procps` on Cygwin
then
    shell=$(procps --pid $$ --format comm=)
else
    # `ps` shows full path on OS X
    shell=$(basename $(ps -p $$ -o comm=))
fi

## SHELL OPTIONS ##
if [[ $shell = bash ]]
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
        printf $@
    }
fi

## LOGGING ##
if [[ $shell = bash ]] && ((BASH_VERSINFO <= 3))
then
    # No associative arrays in Bash 3, so only rudimentary logging
    log() {
        printf "$1: $2\n" > /dev/stderr
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
            # `> /dev/stderr` is equivalent to `>&2`
            printf "${color[$1]}$1:\e[m $2\n" > /dev/stderr
        fi
    }
fi

## VERSION ##
# version is the Mercurial revision number
script_version() {
    # offset is `11` and `7`, length from the right is `-2`
    printf "${1:11:$((${#1} - 11 - 2))} (${2:7:$((${#2} - 7 - 2))})"
}

shell_version() {
    if [[ $shell = bash ]]
    then
        printf %s.%s.%s ${BASH_VERSINFO[@]:0:3}
    else
        printf $ZSH_VERSION
    fi
}

os_version() {
    # CYGWIN
    if   [[ $OSTYPE = cygwin ]]
    then
        osver=$(uname --kernel-release)
        printf "Cygwin ${osver%\(*}"

    # OS X
    elif [[ $OSTYPE =~ ^darwin ]]
    then
        printf "OS X %s" \
        $(python -c 'import platform; print(platform.mac_ver()[0])')

    # UBUNTU
    elif source /etc/lsb-release 2> /dev/null
    then
        printf $DISTRIB_DESCRIPTION

    # RHEL, XENSERVER
    elif awk '
{NF--  # print file except last field
 print}' \
             /etc/redhat-release 2> /dev/null
    then
        :

    # SLES
    elif awk '
NR == 1 {NF--       # print first line except last field
         printf "%s SP ", $0}
NR == 3 {print $3}  # print third field from third line' \
             /etc/SuSE-release   2> /dev/null
    then
        :

    # OTHER LINUX DISTRIBUTION
    else
        printf Unknown

    fi
}

## STANDARD OPTIONS ##
# leading `:`: don't report unknown options (which we can't know in
# advance here)
while getopts :dh option
do
    # DEBUG
    if   [[ $option = d ]]
    then
        verbosity=DEBUG

        log DEBUG "$scriptname $(script_version $VERSION $DATE)"
        log DEBUG "_init.sh $(script_version $_INIT_VERSION $_INIT_DATE)"
        log DEBUG "$shell $(shell_version) on $(os_version) $(uname -m)"
        # https://www.gnu.org/software/gettext/manual/html_node/Locale-Environment-Variables.html
        log DEBUG "LANGUAGE=${LANGUAGE-""}, $(locale | grep LC_ALL), $(locale | grep LANG)"
        # http://pubs.opengroup.org/onlinepubs/7908799/xbd/locale.html
        log DEBUG "LC_NUMERIC: $(locale -k decimal_point)"
        log DEBUG Trace

        if [[ $shell = bash ]]
        then
            PS4='+$(basename $BASH_SOURCE)${FUNCNAME+:$FUNCNAME}[$LINENO]: '
            shopt -os xtrace
        else
            PS4='+%1N[%I]: '
            setopt xtrace
        fi

    # HELP
    elif [[ $option = h ]]
    then
        gettext "\
\`$scriptname\` $description

Usage:
 $scriptname $usage

Options:$options_help
 -d   show debug messages
 -h   show help

THIS SOFTWARE COMES WITHOUT WARRANTY, LIABILITY, OR SUPPORT!
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
    eval $@ &
    spin='-\|/'

    i=0
    while kill -0 $! 2> /dev/null
    do
        # this is just so PyCharm's BashSupport doesn't get confused
        j=$((i += 1))
        printf "\r[${spin:$((j % 4)):1}]"
        sleep 0.1
    done
    printf "\n"
}

## TRAPS ##
# create your own cleanup function in the main script
cleanup() {
    return
}

if [[ $shell = bash ]]
then
    trap cleanup EXIT
else
    setopt trapsasync
    trap "cleanup; exit" EXIT INT HUP TERM
fi

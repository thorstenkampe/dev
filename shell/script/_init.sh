_INIT_VERSION='$Revision$'
_INIT_DATE='$Date$'

scriptname=$(basename $script)

## short instead of long options are used for OS X compatibility

## DOCUMENTATION ##
# - Parameter Expansion
#   - http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02
#   - http://www.tldp.org/LDP/abs/html/parameter-substitution.html
#   - http://wiki.bash-hackers.org/syntax/pe

## TIMELINE ##
# Bash 4.0   (February 2009): assiociative arrays
# Zsh 4.3.11 (December 2010): `${var:offset:length}`
# Bash 4.2   (February 2011): `${var:offset:-length}`
# Zsh 4.3.12 (May 2011):      `${var:offset:-length}`

## SHELL OPTIONS ##
if # bash: stop when an error occurs
   ! shopt -os errexit nounset 2> /dev/null
then
    emulate -R zsh          # zsh: set all options to their defaults
    setopt errexit nounset  # zsh: stop when an error occurs
fi
IFS= # disable word splitting (zsh: for command substitution)

## SHELL ##
if [[ $OSTYPE = cygwin ]]  # `ps` is `procps` on Cygwin
then
    shell=$(procps --pid $$ --format comm=)
else
    # `ps` shows full path on OS X
    shell=$(basename $(ps -p $$ -o comm=))
fi

## INTERNATIONALIZATION ##
# - http://www.gnu.org/software/gettext/manual/gettext.html#sh
export TEXTDOMAINDIR=$(dirname $script)/_translations \
       TEXTDOMAIN=$scriptname

if ! which gettext &> /dev/null
then
    gettext() {
        printf $@
    }
fi

## LOGGING ##
if declare -A loglevel color 2> /dev/null
then
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
else
# No associative arrays in Bash 3, so only rudimentary logging
    log() {
        printf "$1: $2\n" > /dev/stderr
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
    case $OSTYPE in

        # OS X
        darwin*)
            printf \
"OS X $(python -c 'import platform; print(platform.mac_ver()[0])')"
            ;;

        # LINUX
        linux-gnu)
            { # UBUNTU
              if source /etc/lsb-release
                 # catch `unbound variable`/`parameter not set`
                 printf ${DISTRIB_DESCRIPTION=}
              then
# if above doesn't error, do nothing, otherwise continue with `elif`
                  :

              # RHEL, XENSERVER
              elif awk '
{NF--  # print file except last field
 print}' \
                       /etc/redhat-release
              then
                  :

              # SLES
              elif awk '
NR == 1 {NF--       # print first line except last field
         printf "%s SP ", $0}
NR == 3 {print $3}  # print third field from third line' \
                       /etc/SuSE-release
              then
                  :

              # OTHER DISTRIBUTION
              elif
# `platform.linux_distribution` is available from Python 2.6 on
                   python -c \
"import platform; print(' '.join(platform.linux_distribution()[:2]))"
              then
                  :

              fi } 2> /dev/null
            ;;

        # CYGWIN
        cygwin)
            printf Cygwin

    esac
}

## STANDARD OPTIONS ##
# leading `:`: don't report unknown options (which we can't know in
# advance here)
while getopts :dhv option
do
    case $option in
        d)  # DEBUG
            verbosity=DEBUG

            if [[ $shell = bash ]]
            then
                PS4=\
'+$(basename $BASH_SOURCE)${FUNCNAME+:$FUNCNAME}[$LINENO]: '
            else
                PS4='+%1N[%I]: '
            fi

            log DEBUG \
"$scriptname $(script_version $VERSION $DATE)"

            log DEBUG \
"_init.sh $(script_version $_INIT_VERSION $_INIT_DATE)"

            log DEBUG \
"$shell $(shell_version) on $(os_version) $(uname -m)"

            log DEBUG $(locale -ck decimal_point)

            log DEBUG Trace

            if ! shopt -os xtrace 2> /dev/null  # bash
            then
                setopt xtrace                   # zsh
            fi
            ;;

        h)  # HELP
            gettext "\
\`$scriptname\` $description

Usage:
 $scriptname $usage

Options:$options_help
 -d   show debug messages
 -h   show help
 -v   show version

THIS SOFTWARE COMES WITHOUT WARRANTY, LIABILITY, OR SUPPORT!
"
            exit
            ;;

        v)  # VERSION
            printf \
"$scriptname $(script_version $VERSION $DATE)\n"

    esac
done

# reset `OPTIND` for the next round of parsing in main script
OPTIND=1

## SPINNER ##
# taken from http://stackoverflow.com/a/12498305
spinner() {
    # error of the background job will not abort script
    eval $@ &
    spin='-\|/'

    i=0
    while kill -0 $! 2> /dev/null
    do
        printf "\r[${spin:$(((i += 1) % 4)):1}]"
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

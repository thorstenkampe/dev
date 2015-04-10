_INIT_VERSION='$Revision$'
_INIT_DATE='$Date$'

scriptname=$(basename $script)

## short instead of long options are used for OS X compatibility

## LOGGING ##
# Modeled after Python modules `logging` and `colorlog`
verbosity=WARNING  # default level

declare -A loglevel color
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
    shopt -os errexit nounset  # stop when an error occurs
elif [[ $shell = zsh ]]
then
    emulate -R zsh             # set all options to their defaults
    setopt errexit nounset     # stop when an error occurs
fi
IFS=                           # disable word splitting (zsh: for command substitution)

## VERSION ##
# version is the Mercurial revision number
script_version() {
    printf "${1:11:-2} (${2:7:-2})"
}

shell_version() {
    if [[ $shell = bash ]]
    then
        printf %s.%s.%s ${BASH_VERSINFO[@]:0:3}
    elif [[ $shell = zsh ]]
    then
        printf $ZSH_VERSION
    fi
}

os_version() {

    mac_version() {
        printf \
"OS X $(python -c 'import platform; print(platform.mac_ver()[0])')"
    }

    ubuntu_version() {
        source /etc/lsb-release
        # We want to catch `unbound variable`/`parameter not set`
        # - POSIX - 2.6.2 Parameter Expansion
        #   http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02
        # - Advanced Bash-Scripting Guide - 10.2. Parameter Substitution
        #   http://www.tldp.org/LDP/abs/html/parameter-substitution.html
        printf ${DISTRIB_DESCRIPTION=}
    }

    redhat_version() {
        awk '
{NF--  # print file except last field
 print}' \
            /etc/redhat-release
    }

    suse_version() {
        awk '
NR == 1 {NF--       # print first line except last field
         printf "%s SP ", $0}
NR == 3 {print $3}  # print third field from third line' \
            /etc/SuSE-release
    }

    generic_linux() {
        # `platform.linux_distribution` is available from Python 2.6 on
        python -c \
"import platform; print(' '.join(platform.linux_distribution()[:2]))"
    }

    case $OSTYPE in

        # OS X
        darwin*)
            mac_version
            ;;

        # LINUX
        linux-gnu)
            { # UBUNTU
              if   ubuntu_version
              then   # if `ubuntu_version` doesn't error, do nothing,
                  :  # otherwise continue with `redhat_version`

              # RHEL, XENSERVER
              elif redhat_version
              then
                  :

              # SLES
              elif suse_version
              then
                  :

              # OTHER DISTRIBUTION
              elif generic_linux
              then
                  :

              fi } 2> /dev/null
            ;;

        # CYGWIN
        cygwin)
            printf Cygwin

    esac
}

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

elif [[ $shell = zsh ]]
then
    setopt trapsasync
    trap "cleanup; exit 1" EXIT INT HUP TERM
fi

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
                PS4='+$(basename $BASH_SOURCE)${FUNCNAME+:$FUNCNAME}[$LINENO]: '
            elif [[ $shell = zsh ]]
            then
                PS4='+%1N[%I]: '
            fi

            log DEBUG "$scriptname $(script_version $VERSION $DATE)"
            log DEBUG "_init.sh $(script_version $_INIT_VERSION $_INIT_DATE)"
            log DEBUG "$shell $(shell_version) on $(os_version) $(uname -m)"
            log DEBUG $(locale -ck decimal_point)
            log DEBUG Trace

            if [[ $shell = bash ]]
            then
                shopt -os xtrace
            elif [[ $shell = zsh ]]
            then
                setopt xtrace
            fi
            ;;

        h)  # HELP
            gettext "\
\`$scriptname\` $description

Usage:
 $scriptname $usage

Options:
$options_help

 -d   show debug messages
 -h   show help
 -v   show version
"
            exit
            ;;
        v)  # VERSION
            printf "$scriptname $(script_version $VERSION $DATE)\n"
            exit

    esac
done

# reset `OPTIND` for the next round of parsing in main script
OPTIND=1

# Associative array for additional user options
declare -A opts

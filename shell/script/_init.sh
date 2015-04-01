_INIT_VERSION='$Revision$'
_INIT_DATE='$Date$'

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
    shell=$(procps --pid $$ \
                   --format comm=)
else
    # `ps` shows full path on OS X
    shell=$(basename $(ps -p $$ -o comm=))
fi

## OPTIONS ##
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

mac_version() {
    printf \
"OS X $(python -c 'import platform; print(platform.mac_ver()[0])')"
}

ubuntu_version() {
    source /etc/lsb-release
    printf $DISTRIB_DESCRIPTION
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

linux_version() {
    { if   linuxver=$(ubuntu_version)  # Ubuntu
      then :
      elif linuxver=$(redhat_version)  # RHEL, XenServer
      then :
      elif linuxer=$(suse_version)     # SLES
      then :
      # `platform.linux_distribution` is available from Python 2.6 on
      elif linuxver=$(python -c \
"import platform; print(' '.join(platform.linux_distribution()[:2]))")
      then :
      fi } 2> /dev/null

    printf $linuxver
}

os_version() {
    case $OSTYPE in
        (darwin*)   printf $(mac_version)   ;;
        (linux-gnu) printf $(linux_version) ;;
        (cygwin)    printf Cygwin
    esac
}

## DEBUGGING ##
debug() {
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
        trap "setopt xtrace" EXIT
    fi
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

## WRAPPERS ##
gethelp() {
    gettext $help
}

getversion() {
    printf "$scriptname $(script_version $VERSION $DATE)\n"
}

# taken from http://stackoverflow.com/a/12498305
spinner() {
    # error of the backgrounded command will not abort script
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

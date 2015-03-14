_INIT_VERSION='$Revision$'
_INIT_DATE='$Date$'

## short instead of long options are used for OS X compatibility

## LOGGING ##
# Modeled after Python modules `logging` and `colorlog`
verbosity=30  # default level is `WARNING`

log() {
    # For color codes see http://en.wikipedia.org/wiki/ANSI_escape_code#Colors
    case $1 in
        (CRITICAL) loglevel=10
                   color=$'\e[1;31m' ;;  # brightred
        (ERROR)    loglevel=20
                   color=$'\e[0;31m' ;;  # red
        (WARNING)  loglevel=30
                   color=$'\e[0;33m' ;;  # yellow
        (INFO)     loglevel=40
                   color=$'\e[0;32m' ;;  # green
        (DEBUG)    loglevel=50
                   color=$'\e[0;37m' ;;  # white
        (*)        log ERROR \
"unknown logging level \"$1\". Specify logging level \`CRITICAL\`, \
\`ERROR\`, \`WARNING\`, \`INFO\`, OR \`DEBUG\`."
                   exit 2  # indicates "incorrect usage"
    esac

    if ((loglevel <= verbosity))
    then
        # `> /dev/stderr` is equivalent to `>&2`
        printf "$color$1:\e[m $2\n" > /dev/stderr
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

case $shell in
    (bash) is_bash=true  ;;
    (zsh)  is_bash=false ;;
    (*)    log CRITICAL \
"shell \`$shell\` is not supported. Only \`bash\` and \`zsh\` are \
supported."
           exit 2  # indicates "incorrect usage"
esac

## OPTIONS ##
if $is_bash
then
    shopt -os errexit nounset  # stop when an error occurs
else
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
    if $is_bash
    then
        printf %s.%s.%s ${BASH_VERSINFO[@]:0:3}
    else
        printf $ZSH_VERSION
    fi
}

mac_version() {
    printf \
"OS X $(python -c 'import platform; print(platform.mac_ver()[0][3:])')"
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
    python_version=$(python -V 2>&1)

    if [[ -r /etc/lsb-release ]]       # Ubuntu
    then
        ubuntu_version

    elif [[ -r /etc/redhat-release ]]  # RHEL, XenServer
    then
        redhat_version

    elif [[ -r /etc/SuSE-release ]]    # SLES
    then
        suse_version

    # `platform.linux_distribution` is available from Python 2.6 on
    elif [[ $python_version > "Python 2.6" || \
            $python_version = "Python 2.6" ]]
    then
        python -c \
"import platform; print(' '.join(platform.linux_distribution()[:2]))"

    fi
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
    verbosity=50  # debug level

    if $is_bash
    then
        PS4='+$(basename $BASH_SOURCE)${FUNCNAME+:$FUNCNAME}[$LINENO]: '
    else
        PS4='+%1N[%I]: '
    fi

    log DEBUG "$scriptname $(script_version $VERSION $DATE)"

    log DEBUG "_init.sh $(script_version $_INIT_VERSION $_INIT_DATE)"

    log DEBUG "$shell $(shell_version) on $(os_version) $(uname -m)"

    log DEBUG $(locale -ck decimal_point)

    log DEBUG Trace

    if $is_bash
    then
        shopt -os xtrace
    else
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
        printf $*
    }
fi

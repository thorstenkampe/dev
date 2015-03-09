_INIT_VERSION='$Revision$'
_INIT_DATE='$Date$'

## LOGGING ##
# Modeled after Python modules `logging` and `colorlog`
verbosity=30                   # default level is `warning`

declare -A colors
# Assigning associative array elements via subscript is the only
# syntax bash and zsh share
colors[red]=$'\e[0;31m'
colors[brightred]=$'\e[1;31m'
colors[green]=$'\e[0;32m'
colors[yellow]=$'\e[0;33m'
colors[white]=$'\e[0;37m'
colors[reset]=$'\e[m'

log() {
    # For color codes see
    # http://en.wikipedia.org/wiki/ANSI_escape_code#Colors
    case $1 in
        (CRITICAL) loglevel=10
                   color=${colors[brightred]} ;;
        (ERROR)    loglevel=20
                   color=${colors[red]}       ;;
        (WARNING)  loglevel=30
                   color=${colors[yellow]}    ;;
        (INFO)     loglevel=40
                   color=${colors[green]}     ;;
        (DEBUG)    loglevel=50
                   color=${colors[white]}     ;;
        (*)        log ERROR \
"unknown logging level \"$1\". Specify logging level \`CRITICAL\`, \
\`ERROR\`, \`WARNING\`, \`INFO\`, OR \`DEBUG\`."
                   exit 2      # indicates "incorrect usage"
    esac

    if ((loglevel <= verbosity))
    then
        { printf "$color$1:${colors[reset]} $2\n" | fold --spaces \
                                                         --width 70
        } > /dev/stderr        # `> /dev/stderr` is equivalent to `>&2`
    fi
}

## SHELL ##
if [[ $OSTYPE = cygwin ]]      # `ps` is `procps` on Cygwin
then
    shell=$(procps --pid $$ \
                   --format comm=)
else
    shell=$(ps --pid $$     \
               --format comm=)
fi

if [[ $shell = bash ]]
then
    is_bash=true
elif [[ $shell = zsh ]]
then
    is_bash=false
else
    log CRITICAL \
"shell \`$shell\` is not supported. Only \`bash\` and \`zsh\` are \
supported."
    exit 2                     # indicates "incorrect usage"
fi

## OPTIONS ##
if $is_bash
then
    shopt -os errexit nounset  # stop when an error occurs
else
    emulate -R zsh             # set all options to their defaults
    setopt errexit nounset     # stop when an error occurs
fi
IFS=                           # disable word splitting (zsh: for command substitution)

## DEBUGGING ##
debug() {
    verbosity=50               # debug level

    if $is_bash
    then
        shell_version=$(printf %s.%s.%s ${BASH_VERSINFO[@]:0:3})
        PS4='+$(basename $BASH_SOURCE)${FUNCNAME+:$FUNCNAME}[$LINENO]: '
    else
        shell_version=$ZSH_VERSION
        PS4='+%1N[%I]: '
    fi

    log DEBUG $(version)

    log DEBUG "_init.sh ${_INIT_VERSION:11:-2} (${_INIT_DATE:7:-2})"

    log DEBUG \
"$shell $shell_version on $(uname --operating-system) $(uname \
--machine)"

    log DEBUG $(locale --category-name \
                       --keyword-name  \
                       decimal_point)

    log DEBUG "Trace"

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

## VERSION ##
# version is the Mercurial revision number
version() {
    printf "$scriptname %s (%s)\n" \
           ${VERSION:11:-2}        \
           ${DATE:7:-2}
}

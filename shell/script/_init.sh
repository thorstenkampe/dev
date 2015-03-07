# $Revision$
# $Date$

## LOGGING ##
# Modeled after Python's module `logging`
# https://docs.python.org/3/library/logging.html
verbosity=30                   # default level is `warning`

log() {
    case $1 in
        (CRITICAL) loglevel=10 ;;
        (ERROR)    loglevel=20 ;;
        (WARNING)  loglevel=30 ;;
        (INFO)     loglevel=40 ;;
        (DEBUG)    loglevel=50 ;;
        (*)        log ERROR \
"unknown logging level \"$1\". Specify logging level \`CRITICAL\`, \
\`ERROR\`, \`WARNING\`, \`INFO\`, OR \`DEBUG\`."
                   exit 2      # indicates "incorrect usage"
    esac

    if ((loglevel <= verbosity))
    then
        # Expand escaped characters, wrap at 70 characters, indent
        # wrapped lines
        { printf "$1: $2\n" | \
          fold --spaces       \
               --width 70   | \
          sed '2~1s/^/  /'
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
    log ERROR \
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


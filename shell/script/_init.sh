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
    { printf "ERROR: Shell \`$shell\` is not supported.\n"
      printf 'Only `bash` and `zsh` are supported.\n'
    } > /dev/stderr
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
    decimal_point=$(locale --category-name \
                           --keyword-name  \
                           decimal_point)
    platform="$(uname --operating-system) $(uname --machine)"

    if $is_bash
    then
        shell_version=$(printf %s.%s.%s ${BASH_VERSINFO[@]:0:3})
        PS4='+$(basename $BASH_SOURCE)${FUNCNAME+:$FUNCNAME}[$LINENO]: '
    else
        shell_version=$ZSH_VERSION
        PS4='+%1N[%I]: '
    fi

    { printf "DEBUG: $shell $shell_version on $platform\n"
      printf "DEBUG: $decimal_point\n"
      printf "DEBUG: Trace\n"
    } > /dev/stderr            # `> /dev/stderr` is equivalent to `>&2`

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
# - version is MODIFICATION_DATE.TIME.FILE_CHECKSUM (YYMMDD.HHMM_UTC.CRC-16_HEX)
version() {
    # bash treats numbers with leading zeroes as octal
    printf "$scriptname %s.%04x\n"    \
           $(date --reference $script \
                  --utc               \
                  +%y%m%d.%H%M)       \
           $((10#$(sum $script |      \
                   cut --fields 1     \
                       --delimiter " ")))
}

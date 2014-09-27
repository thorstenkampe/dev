##
if [[ $OSTYPE = cygwin ]]      # `ps` is `procps` on Cygwin
then
    shell=$(procps --pid $$ --format comm=)
else
    shell=$(ps --pid $$ --format comm=)
fi

## OPTIONS ##
if [[ $shell = bash ]]
then
    shopt -os errexit nounset  # stop when an error occurs
else
    emulate -R zsh             # set all options to their defaults
    setopt errexit nounset     # stop when an error occurs
fi
IFS=                           # disable word splitting (zsh: for command substitution)

## DEBUGGING ##
if [[ $shell = bash ]]
then
    lcyan=$'\e[1;36m'
    reset=$'\e[m'
    PS4='\[$lcyan\]+\[$reset\]$(basename $BASH_SOURCE)${FUNCNAME+:$FUNCNAME}[$LINENO]\[$lcyan\]:\[$reset\] '

    function debug {
    printf "${lcyan}DEBUG:$reset Trace:\n" >&2
    shopt -os xtrace
    }
else
    PS4='%B%F{cyan}+%b%f%1N[%I]%B%F{cyan}:%b%f '

    function debug {
    print -P "%B%F{cyan}DEBUG:%b%f Trace:" >&2
    trap "setopt xtrace" EXIT
    }
fi

## INTERNATIONALIZATION ##
# http://www.gnu.org/software/gettext/manual/gettext.html#sh
export TEXTDOMAINDIR=$(dirname $script)/_translations \
       TEXTDOMAIN=$scriptname

if ! which gettext &> /dev/null
then
    function gettext {
    printf $*
    }
fi

## VERSION ##
# version is DATE.TIME.CHECKSUM (YYMMDD.HHMM_UTC.CRC-16_HEX)
version=$(printf "%s %s.%04x"      \
        $scriptname                \
        $(date --reference $script \
               --utc +%y%m%d.%H%M) \
        $(sum $script |
          cut --fields 1           \
              --delimiter " "))

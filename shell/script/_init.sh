##
# `ps` in `procps` on Cygwin
if [[ $OSTYPE = cygwin ]]
then
    function ps {
    procps $*
    }
fi

if [[ $(ps --pid $$ --format comm=) = bash ]]
then
    ## OPTIONS ##
    shopt -os errexit nounset  # stop when an error occurs
    IFS=                       # disable word splitting

    ## DEBUGGING ##
    function debug {
    lcyan=$'\e[1;36m'
    reset=$'\e[m'
    PS4='\[$lcyan\]+\[$reset\]$(basename $BASH_SOURCE)${FUNCNAME+:$FUNCNAME}[$LINENO]\[$lcyan\]:\[$reset\] '

    printf "${lcyan}DEBUG:$reset Trace:\n" >&2

    shopt -os xtrace
    }

else
    ## OPTIONS ##
    emulate -R zsh             # set all options to their defaults
    setopt errexit nounset     # stop when an error occurs
    IFS=                       # disable word splitting (for command substitution)

    ## DEBUGGING ##
    function debug {
    PS4='%B%F{cyan}+%b%f%1N[%I]%B%F{cyan}:%b%f '

    print -P "%B%F{cyan}DEBUG:%b%f Trace:" >&2

    trap "setopt xtrace" EXIT
    }
fi

## INTERNATIONALIZATION ##
# http://www.gnu.org/software/gettext/manual/gettext.html#sh
if which gettext &> /dev/null
then
    export TEXTDOMAINDIR=$(dirname $script)/_translations \
           TEXTDOMAIN=$scriptname
else
    function gettext {
    printf $*
    }
fi

## VERSION ##
# version is DATE.TIME.CHECKSUM (YYMMDD.HHMM_UTC.CRC-16_HEX)
function version {
printf "%s %s.%04x\n" $scriptname                                    \
                      $(date --reference $script --utc +%y%m%d.%H%M) \
                      $(sum $script | cut --fields 1 --delimiter " ")
}

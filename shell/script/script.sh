#! /usr/bin/env bash

help='SCRIPT DESCRIPTION

Usage:
 SCRIPT [options]

Options:
 -h   show help
 -d   show debug messages'

# INITIALIZATION #
IFS=  # disable word splitting
# https://www.gnu.org/software/gettext/manual/html_node/Locale-Environment-Variables.html
export LANG=en_US.UTF-8  # "neutral" environment
shopt -os nounset pipefail errexit

# LOGGING #
# modeled after Python modules `logging` and `colorlog`
verbosity=WARNING  # default level
declare -A loglevel color color_codes
loglevel=([CRITICAL]=50 [ERROR]=40 [WARNING]=30 [INFO]=20 [DEBUG]=10)
color=([CRITICAL]=brightred [ERROR]=red [WARNING]=yellow [INFO]=green [DEBUG]=white)
# for color codes see http://en.wikipedia.org/wiki/ANSI_escape_code#Colors
color_codes=([brightred]='1;31' [red]='0;31' [yellow]='0;33' [green]='0;32' [white]='0;37')

function log {
    if ((loglevel[$1] >= loglevel[$verbosity]))
    then
        if [[ -t 2 ]]  # only output color if stderr is attached to tty
        then
            echo -e "\e[${color_codes[${color[$1]}]}m$1\e[m: $2"
        else
            echo -e "$1: $2"
        fi > /dev/stderr
    fi
}

# TRAPS #
# * create your own handler in the main section
# * trap EXIT signal for exit handler; the exit handler will always run (after
#   the error handler)

function error_handler {
    error_code=$?
    echo
    log ERROR "received $1 signal, exiting..."
    exit $error_code
}

for signal in ERR INT TERM
do
    # shellcheck disable=SC2064
    trap "error_handler $signal" $signal
done

# DEFAULT OPTIONS #
function default_options {
    if   [[ $option == h ]]
    then
        echo "$help"
        exit

    elif [[ $option == d ]]
    then
        PS4='+$(basename $BASH_SOURCE)${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
        verbosity=DEBUG

        log DEBUG "bash $BASH_VERSION"
        shopt -os xtrace

    elif [[ $option == '?' ]]
    then
        exit 1
    fi
}

# MAIN CODE STARTS HERE #
while getopts hd option
do
    default_options
done
shift $((OPTIND - 1))  # remove options from command line

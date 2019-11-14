#! /usr/bin/env bash

help='Usage: script.sh'

# INITIALIZATION #
PS4='+$(basename "$BASH_SOURCE")${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
shopt -os nounset pipefail errexit
export LANG=en_US.UTF-8  # neutral environment

function log {
    # `<13>` = 8 * user + notice (https://en.wikipedia.org/wiki/Syslog#Facility)
    logger --no-act --stderr --socket-errors off --tag "$1" "$2"
}

# OPTIONS #
function do_options {
    while getopts h option
    do
        case $option in
            (h)
                echo "$help"
                exit
                ;;

            ('?')
                exit 1
        esac
    done
    shift $((OPTIND - 1))  # remove options from command line
}

# MAIN CODE STARTS HERE #
# shellcheck disable=SC2128
if [[ $BASH_SOURCE == "$0" ]]
then
    do_options "$@"
fi

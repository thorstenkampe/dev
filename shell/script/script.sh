#! /usr/bin/env bash

# INITIALIZATION #
PS4='+$(basename "$BASH_SOURCE")${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit
export LANG=en_US.UTF-8  # neutral environment

PATH=/usr/sbin:$PATH

help='Usage: script.sh [-l <logfile>]'

function log {
    echo "$(date +"%F %T")" "$1": "$2" > /dev/stderr
}

if [[ $OSTYPE == cygwin ]]
then
    function ps {
        procps "$@"
    }
fi

function error_handler {
    status=$?
    log ERROR "command \"$1\" in line $2${3:+ (function $3)}"
    exit $status
}

trap 'error_handler "$BASH_COMMAND" $LINENO ${FUNCNAME-}' err

# OPTIONS #
function do_options {
    while getopts hl: option
    do
        case $option in
            (h)
                echo "$help"
                exit
                ;;

            (l)
                # on Cygwin there might not be a parent process
                parent_process=$(ps --pid $PPID --format comm=) || true
                if [[ $parent_process != logsave ]]
                then
                    exec logsave -a "$OPTARG" "$0" "$@"
                fi
                ;;

            ('?')
                exit 1
        esac
    done
}

# MAIN CODE STARTS HERE #
function main {
    shift $((OPTIND - 1))  # remove options from command line
}

# shellcheck disable=SC2128
if [[ $BASH_SOURCE == "$0" ]]
then
    do_options "$@"
    main "$@"
fi

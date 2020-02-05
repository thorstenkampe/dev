#! /usr/bin/env bash

# INITIALIZATION #
PS4='+$(basename "$BASH_SOURCE")${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit
export LANG=en_US.UTF-8  # neutral environment

help='Usage: script.sh [-l <logfile>]'

function log {
    declare -A loglevel=([CRITICAL]=10 [ERROR]=20 [WARNING]=30 [INFO]=40 [DEBUG]=50)

    if ((loglevel[$1] <= loglevel[${VERBOSITY:-WARNING}]))
    then
        # log message prefix `<13>` = 8 * user + notice (https://en.wikipedia.org/wiki/Syslog#Facility)
        logger --no-act --stderr --socket-errors off --tag "$1" "$2"
    fi
}

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
                parent_process=$(ps --pid $PPID --format comm=)
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
    :
}

# shellcheck disable=SC2128
if [[ $BASH_SOURCE == "$0" ]]
then
    do_options "$@"
    main
fi

#! /usr/bin/env bash

# INITIALIZATION #
PS4='+$(basename "$BASH_SOURCE")${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit
export LANG=en_US.UTF-8  # neutral environment

function log {
    echo "$(date +"%F %T")" "$1": "$2" > /dev/stderr
}

function error_handler {
    status=$?
    log ERROR "command \"$1\" in line $2${3:+ (function $3)}"
    exit $status
}

trap 'error_handler "$BASH_COMMAND" $LINENO ${FUNCNAME-}' err

# MAIN CODE STARTS HERE #
function main {
    :
}

# shellcheck disable=SC2128
if [[ $BASH_SOURCE == "$0" ]]
then
    main "$@"
fi

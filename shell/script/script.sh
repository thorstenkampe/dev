#! /usr/bin/env bash

# shellcheck disable=SC2154
source "$(dirname "$0")/toolbox.sh"
init

_params=( "$@" )
scriptname=$(basename "$0")

# MAIN CODE STARTS HERE #

# shellcheck disable=SC2016
test_args 'which $arg' mailsend-go

if (( ${#false[@]} )); then
    log error "can't find dependencies: ${false[*]}"
    exit 1
fi

function error_handler {
    log error "command \"$1\" in line $2${3:+ (function $3)}" || true
    #send_mail -to RECIPIENT -sub SUBJECT body -msg MESSAGE || true
}

trap 'error_handler "$BASH_COMMAND" $LINENO ${FUNCNAME-}' err

parse_opts hl:d "$@"
shift $(( OPTIND - 1 ))  # make arguments available as $1, $2...

if set_opt h; then
    echo "Usage: $scriptname [-l <logfile>]"
    echo
    echo Options:
    echo '  -l <logfile>  Log to file'
    echo '  -h            Show help'
    echo '  -d            Show debug and trace messages'
    exit
fi

if set_opt l; then
    log_to_file "${opts[l]}" bash "$0" "${_params[@]}"
fi

if set_opt d; then
    export verbosity=debug
    if ! shopt -oq xtrace; then
        exec bash -x "$0" "${_params[@]}"
    fi
fi

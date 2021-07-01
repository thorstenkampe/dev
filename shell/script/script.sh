#! /usr/bin/env bash

# shellcheck disable=SC2154
source "$(/usr/bin/dirname "$0")/toolbox.sh"
tb_init

_params=( "$@" )
scriptname=$(basename "$0")

# MAIN CODE STARTS HERE #

# shellcheck disable=SC2016
tb_test_args 'which $arg' mailsend-go

if (( ${#false[@]} )); then
    tb_log warn "can't find dependencies: ${false[*]}"
fi

function error_handler {
    tb_log error "command \"$1\" in $2" || true
    #send_mail -to RECIPIENT -sub SUBJECT body -msg MESSAGE || true
}

trap 'error_handler "$BASH_COMMAND" "$(basename "${BASH_SOURCE[0]}")${FUNCNAME:+:${FUNCNAME[0]}}:$LINENO"' err

tb_parse_opts hl:d "$@"
shift $(( OPTIND - 1 ))  # make arguments available as $1, $2...

if tb_set_opt h; then
    echo "Usage: $scriptname [-l <logfile>]"
    echo
    echo Options:
    echo '  -l <logfile>  Log to file'
    echo '  -h            Show help'
    echo '  -d            Show debug and trace messages'
    exit
fi

if tb_set_opt l; then
    tb_log_to_file "${opts[l]}" bash "$0" "${_params[@]}"
fi

if tb_set_opt d; then
    export verbosity=debug
    if ! shopt -oq xtrace; then
        exec bash -x "$0" "${_params[@]}"
    fi
fi

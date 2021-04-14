#! /usr/bin/env bash

# shellcheck disable=SC2154
source "$(dirname "$0")/toolbox.sh"
init

# doesn't work when put into `toolbox.sh`
function is_sourced {
    [[ ${BASH_SOURCE[0]} != "$0" ]]
}

# shellcheck disable=SC2034
_params=( "$@" )
# shellcheck disable=SC2034
scriptname=$(basename "$0")

# MAIN CODE STARTS HERE #

# shellcheck disable=SC2016
test_args 'which $arg' mailsend-go

if (( ${#false[@]} )); then
    log CRITICAL "can't find dependencies: ${false[*]}"
    exit 1
fi

function send_error_email {
    send_mail -to RECIPIENT -sub SUBJECT body -msg MESSAGE || true
}

# stop if script is sourced (i.e. for testing via BATS)
is_sourced && return

#trap send_error_email ERR

parse_opts hl:d "$@"
shift $(( OPTIND - 1 ))  # make arguments available as $1, $2...

if set_opt h; then
    echo "Usage: $scriptname [-h] [-l <logfile>]"
    exit
fi

if set_opt l; then
    log_to_file "${opts[l]}" "$0" "${_params[@]}"
fi

if set_opt d; then
    # shellcheck disable=SC2034
    verbosity=DEBUG
fi

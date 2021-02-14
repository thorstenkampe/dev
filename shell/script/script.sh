#! /usr/bin/env bash

shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit 2> /dev/null || true

PS4='+$(basename "${BASH_SOURCE[0]}")${FUNCNAME:+:$FUNCNAME}[$LINENO]: '

# shellcheck disable=SC2034
_params=( "$@" )
# shellcheck disable=SC2034
scriptname=$(basename "$0")

function is_sourced {
    [[ ${BASH_SOURCE[0]} != "$0" ]]
}

function is_windows {
    [[ $OSTYPE =~ ^(cygwin|msys)$ ]]
}

function parse_opts {
    unset opts OPTIND
    local opt
    declare -gA opts

    while getopts "$1" opt "${@:2}"; do
        if [[ $opt == '?' ]]; then
            # unknown option or required argument missing
            return 1
        else
            opts[$opt]=${OPTARG-}
        fi
    done
}

function set_opt {
    [[ -v opts[$1] ]]
}

function log {
    declare -A loglevel
    loglevel=( [CRITICAL]=10 [ERROR]=20 [WARNING]=30 [INFO]=40 [DEBUG]=50 )
    verbosity=${verbosity-WARNING}

    if (( loglevel[$1] <= loglevel[$verbosity] )); then
        echo -e "$1": "$2" >&2
    fi
}

function log_to_file {
    local parent_process
    parent_process=$(ps --pid $PPID --format comm= || true)

    if [[ $parent_process != logsave ]]; then
        exec logsave -a "$1" "${@:2}"
    fi
}

# https://github.com/muquit/mailsend-go
function send_mail {
    mailsend-go -smtp localhost              \
                -port 25                     \
                -fname "$(whoami)@$HOSTNAME" \
                -from FROM                   \
                auth -user USER              \
                     -pass PASSWORD          \
                "$@"
}

function test_args {
    # split arguments into arrays that evaluate to true and to false
    # `test_args '(( $arg % 2 ))' 1 2 3 4` -> true=(1 3) false=(2 4)
    local arg
    true=()
    false=()

    for arg in "${@:2}"; do
        if eval "$1" &> /dev/null; then
            true+=( "$arg" )
        else
            false+=( "$arg" )
        fi
    done
}

function setupwin {
    if is_windows; then
        PATH=/usr/sbin:/usr/bin:$PATH

        function ps {
            procps "$@"
        }
    fi
}

setupwin

# MAIN CODE STARTS HERE #

deps=(mailsend-go)
# shellcheck disable=SC2016
test_args 'which $arg' "${deps[@]}"

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
    verbosity=DEBUG
else
    verbosity=WARNING
fi

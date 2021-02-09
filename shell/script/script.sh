#! /usr/bin/env bash

shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit 2> /dev/null || true

PS4='+$(basename "${BASH_SOURCE[0]}")${FUNCNAME:+:$FUNCNAME}[$LINENO]: '

_params=( "$@" )
scriptname=$(basename "$0")
USER=$(whoami)

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
    declare -A loglevel=( [CRITICAL]=10 [ERROR]=20 [WARNING]=30 [INFO]=40 [DEBUG]=50 )

    if (( loglevel[$1] <= loglevel[${verbosity-WARNING}] )); then
        echo -e "$1": "$2" >&2
    fi
}

function log_to_file {
    local parent_process
    parent_process=$(ps --pid $PPID --format comm=) || true
    if [[ $parent_process != logsave ]]; then
        exec logsave -a "${opts[l]}" "${BASH_SOURCE[0]}" "${_params[@]}"
    fi
}

function send_mail {
    # https://github.com/muquit/mailsend-go
    mailsend-go -smtp localhost          \
                -port 25                 \
                -fname "$USER@$HOSTNAME" \
                -from FROM               \
                auth -user USER          \
                     -pass PASSWORD      \
                "$@"
}

function test_arguments {
    # test if all arguments satisfy test
    # `test_arguments '(( $arg >= 3 ))' 3 4`
    local arg
    # shellcheck disable=SC2034
    for arg in "${@:2}"; do
        if ! eval "$1"; then
            return 1
        fi
    done
}

if is_windows; then
    PATH=/usr/sbin:/usr/bin:$PATH

    function ps {
        procps "$@"
    }
fi

# MAIN CODE STARTS HERE #

deps=(mailsend-go)

# shellcheck disable=SC2016
if ! test_arguments 'which $arg &> /dev/null' "${deps[@]}"; then
    log CRITICAL "cannot find at least one dependency (${deps[*]})"
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
    log_to_file
fi

if set_opt d; then
    verbosity=DEBUG
else
    verbosity=WARNING
fi

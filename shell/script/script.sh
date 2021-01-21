#! /usr/bin/env bash

shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit

PS4='+$(basename "${BASH_SOURCE[0]}")${FUNCNAME:+:$FUNCNAME}[$LINENO]: '

_params=("$@")

if [[ $OSTYPE =~ ^(cygwin|msys)$ ]]; then
    PATH=/usr/sbin:/usr/bin:$PATH
    USER=$(whoami)

    function ps {
        procps "$@"
    }
fi

function parse_opts {
    unset opts OPTIND
    local opt
    declare -gA opts

    while getopts "$1" opt "${@:2}"; do
        if [[ $opt == '?' ]]; then
            # unknown option or required argument missing
            exit 1
        else
            opts[$opt]=${OPTARG-}
        fi
    done
}

function set_opt {
    [[ -v opts[$1] ]]
}

function log {
    declare -A loglevel=([CRITICAL]=10 [ERROR]=20 [WARNING]=30 [INFO]=40 [DEBUG]=50)

    if (( loglevel[$1] <= loglevel[${verbosity-WARNING}] )); then
        echo "$1": "$2" >&2
    fi
}

function log_to_file {
    local parent_process
    # on Cygwin there might not be a parent process
    parent_process=$(ps --pid $PPID --format comm=) || true
    if [[ $parent_process != logsave ]]; then
        exec logsave -a "${opts[l]}" "$BASH_ARGV0" "${_params[@]}"
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

# MAIN CODE STARTS HERE #

function send_error_email {
    send_mail -to RECIPIENT -sub SUBJECT body -msg MESSAGE || true
}

# stop if script is sourced (i.e. for testing via BATS)
[[ ${BASH_SOURCE[0]} != "$0" ]] && return

trap send_error_email ERR

parse_opts hl: "$@"
shift $(( OPTIND - 1 ))  # make arguments available as $1, $2...

if set_opt h; then
    echo 'Usage: script.sh [-h] [-l <logfile>]'
    exit

elif set_opt l; then
    log_to_file
fi

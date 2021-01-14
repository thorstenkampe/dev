#! /usr/bin/env bash

shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit

PS4='+$(basename "${BASH_SOURCE[0]}")${FUNCNAME:+:$FUNCNAME}[$LINENO]: '

function parse_opts {
    unset opts OPTIND
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

if [[ $OSTYPE =~ ^(cygwin|msys)$ ]]; then
    PATH=/usr/bin:$PATH

    function ps {
        procps "$@"
    }
fi

function sendmail {
    local user
    user=$(whoami)

    # https://github.com/muquit/mailsend-go
    mailsend-go -smtp localhost          \
                -port 25                 \
                -fname "$user@$HOSTNAME" \
                -from FROM               \
                auth -user USER          \
                     -pass PASSWORD      \
                "$@"
}

# if script is sourced (i.e. for testing via BATS)
if [[ ${BASH_SOURCE[0]} != "$0" ]]; then
    return
fi

# MAIN CODE STARTS HERE #

function error_handler {
    exit_code=$?
    sendmail -to RECIPIENT     \
             -sub SUBJECT      \
             body -msg MESSAGE \
    || true
    exit $exit_code
}

trap error_handler ERR

parse_opts h "$@"
shift $((OPTIND - 1))  # make arguments available as $1, $2...

if set_opt h; then
    echo 'Usage: script.sh [-h]'
    exit
fi

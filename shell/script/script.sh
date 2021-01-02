#! /usr/bin/env bash

shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit

function parse_opts {
    unset opts OPTIND
    declare -gA opts

    while getopts "$1" opt "${@:2}"; do
        if [[ $opt == '?' ]]; then
            # unknown option or required argument missing
            exit 1
        else
            opts[-$opt]=${OPTARG-}
        fi
    done
}

function log {
    echo "$1: $2" >&2
}

function set_opt {
    [[ -v opts[$1] ]]
}

function debug {
    PS4='+$(basename "${BASH_SOURCE[0]}")${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
    shopt -os xtrace
}

# MAIN CODE STARTS HERE #
# `getopts a:b`: -a -b -> -a=-b; -ab -> -a=b (should be "required argument missing")
parse_opts dh "$@"
shift $((OPTIND - 1))  # make arguments available as $1, $2...

if set_opt '-h'; then
    echo 'Usage: script.sh [-d] [-h]'
    exit

elif set_opt '-d'; then
    debug
fi

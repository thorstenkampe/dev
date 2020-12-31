#! /usr/bin/env bash

shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit

PS4='+$(basename "${BASH_SOURCE[0]}")${FUNCNAME:+:$FUNCNAME}[$LINENO]: '

function log {
    echo "$1: $2" >&2
}

function parse_opts {
    unset opts OPTIND
    declare -gA opts
    local optstr=$1
    shift

    while getopts "$optstr" opt; do
        if [[ $opt == '?' ]]; then  # unknown option or required argument missing
            exit 1
        else
            opts[$opt]=${OPTARG-}
        fi
    done
}

function has_opt {
    # get option argument with `${opts[<opt>]}`
    [[ -v opts[$1] ]]
}

# MAIN CODE STARTS HERE #
# !! `getopts a:b`: -a -b -> -a='-b'; -ab -> -a='b'; -a=b -> -a='=b'
parse_opts '' "$@"   # script supports no options
shift $((OPTIND-1))  # make arguments available as $1, $2...

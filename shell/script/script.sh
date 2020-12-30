#! /usr/bin/env bash

shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit

PS4='+$(basename "${BASH_SOURCE[0]}")${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
_params=("$@")

function log {
    echo "$1: $2" >&2
}

function parse_options {
    unset opts OPTIND
    declare -gA opts

    while getopts "$1" opt "${_params[@]}"
    do
        if [[ $opt == '?' ]]  # invalid option or required argument missing
        then
            exit 1
        else
            # shellcheck disable=SC2034
            opts[$opt]=${OPTARG-}
        fi
    done
}

function is_option_set {
    # get option argument with `${opts[<opt>]}`
    [[ -v opts[$1] ]]
}

# MAIN CODE STARTS HERE #
# !! `getopts a:b`: -a -b -> -a='-b'; -ab -> -a='b'; -a=b -> -a='=b'
parse_options 'a:'     # script supports no options
shift $((OPTIND-1))  # make arguments available as $1, $2...

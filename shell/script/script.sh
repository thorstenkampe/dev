#! /usr/bin/env bash

shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit

PS4='+$(basename "${BASH_SOURCE[0]}")${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
_args=("$@")

#
function log {
    echo "$1: $2" >&2
}

function parse_options {
    declare -gA options

    while getopts "$1" option "${_args[@]}"
    do
        if [[ $option == '?' ]]
        then
            exit 1
        else
            # shellcheck disable=SC2034
            options[$option]=${OPTARG-}
        fi
    done
}

function is_option_set {
    [[ -v options[$1] ]]  # `-v` for associative arrays in bash 4.3
}

# MAIN CODE STARTS HERE #
# !! `getopts a:b`: -a -b -> -a='-b'; -ab -> -a='b'; -a=b -> -a='=b'
parse_options ''  # script supports no options

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
            options[$option]=${OPTARG-}
        fi
    done
}

# MAIN CODE STARTS HERE #
# !! `getopts a:b`: -a -b -> -a='-b'; -ab -> -a='b'; -a=b -> -a='=b'
# test for option: `[[ -v options[<option>] ]]`
parse_options ''  # script supports no options

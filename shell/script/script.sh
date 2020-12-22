#! /usr/bin/env bash

# initialization #
PS4='+$(basename "${BASH_SOURCE[0]}")${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit

PATH=/usr/bin:/bin:$PATH  # Cygwin: standard POSIX paths first

# logging #
# run `logsave -a <logfile> script.sh [...]` to log to file
function log {
    echo "$(date +"%F %T") $1: $2" >&2
}

# options #
_args=("$@")
function parse_options {
    declare -gA options

    while getopts "$1" option "${_args[@]}"
    do
        case $option in
            ('?')
                exit 1
                ;;

            (*)
                # fix for "getopts sees second option as argument for first option"
                # (`getopts a:` and `script.sh -a -b`)
                if [[ ${OPTARG-} == -* ]]
                then
                    echo "$0: option requires an argument -- $option" >&2
                    exit 1
                fi

                # shellcheck disable=SC2034
                options[$option]=${OPTARG-}
                ;;
        esac
    done
}

# MAIN CODE STARTS HERE #
# test for option: `[[ -v options[<option>] ]]`
parse_options ''  # script supports no options

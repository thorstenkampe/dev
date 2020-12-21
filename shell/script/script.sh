#! /usr/bin/env bash

# initialization #
PS4='+$(basename "${BASH_SOURCE[0]}")${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit
export LANG=en_US.UTF-8  # neutral environment

PATH=/usr/bin:/bin:$PATH  # Cygwin: standard POSIX paths first

# logging #
# run `logsave -a <logfile> script.sh [...]` to log to file
function log {
    echo "$(date +"%F %T") $1: $2" > /dev/stderr
}

# options #
_args=("$@")
declare -A options
function parse_options {
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
                    echo "$0: option requires an argument -- $option" > /dev/stderr
                    exit 1
                fi

                # shellcheck disable=SC2034
                options[$option]=${OPTARG-}
                ;;
        esac
    done
}

# MAIN CODE STARTS HERE #
# below is an example how to use the parsed options
parse_options a:bc

# $ script.sh -a 1 -b
# a: 1
# b:
for option in a b c
do
    # shellcheck disable=SC2102
    # `-v` for associative arrays in bash 4.3
    if [[ -v options[$option] ]]
    then
        echo "$option: ${options[$option]}"
    fi
done

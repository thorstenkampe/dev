#! /usr/bin/env bash

# INITIALIZATION #
PS4='+$(basename "${BASH_SOURCE[0]}")${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit
export LANG=en_US.UTF-8  # neutral environment

PATH=/usr/bin:/bin:$PATH  # Cygwin: standard POSIX paths first

# fix for `getopts x:` and `script -x -y` (getopts sees `-y` as argument for `-x`)
function is_argument_option {
    if [[ $OPTARG == -* ]]
    then
        echo "$0: option requires an argument -- $option" > /dev/stderr
        exit 1
    fi
}

# OPTIONS #
while getopts '' option
do
    case $option in
        ('?')
            exit 1
    esac
done

# MAIN CODE STARTS HERE #

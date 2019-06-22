#! /usr/bin/env bash

help='SCRIPT DESCRIPTION

Usage:
 SCRIPT [options]

Options:
 -h   show help
 -d   show debug messages
'

script=$0
# shellcheck source=_init.sh
source "$(dirname "$script")"/_init.sh

while getopts hd option  # option string needs standard options
do
    if [[ $option == '?' ]]
    then
        exit 1
    fi
done
shift $((OPTIND - 1))   # remove options from command line

## MAIN CODE STARTS HERE ##

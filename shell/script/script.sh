#! /usr/bin/env bash

help='`SCRIPT` DESCRIPTION

Usage:
 SCRIPT USAGE

Options:
 -d   show debug messages
 -h   show help
'

script=$0
source $(dirname "$script")/_init.sh

while getopts dh option
do
    if   [[ $option == d ]]
    then
        debug
    elif [[ $option == h ]]
    then
         help
    elif [[ $option == "?" ]]
    then
        exit 1
    fi
done
shift $((OPTIND - 1))    # remove options from command line

## MAIN CODE STARTS HERE ##

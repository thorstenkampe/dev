#! /usr/bin/env bash

help='`SCRIPT` DESCRIPTION

Usage:
 SCRIPT USAGE

Options:
 -h   show help
'

script=$0
source "$(dirname "$script")"/_init.sh

while getopts h option  # option string needs standard options
do
    if [[ $option == "?" ]]
    then
        exit 1
    fi
done
shift $((OPTIND - 1))   # remove options from command line

## MAIN CODE STARTS HERE ##

#! /usr/bin/env bash

VERSION='$Revision$'
DATE='$Date$'

scriptname=$(basename $0)
help="\
\`$scriptname\` does something

Usage:
 $scriptname [-O]

Options:
 -O   do optional stuff
"                           # `-d`, `-v`, and `-h` are always available

script=$0
source "$(dirname "$0")"/_init.sh

while getopts O:dhv option  # option string needs standard options `dhv`
do
    case $option in
        O)                  # test if option is set with `if [[ ${opts[O]+set} ]]`
            opts[O]=$OPTARG
            ;;
        \?)                 # literal `?` indicates unknown option
            exit 1
    esac
done
shift $((OPTIND - 1))       # remove options from command line

## MAIN CODE STARTS HERE ##

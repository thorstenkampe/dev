#! /usr/bin/env bash

script=$0
scriptname=$(basename $0)
source "$(dirname "$0")"/_init.sh

##
VERSION='$Revision$'
DATE='$Date$'

help="\
\`$scriptname\` does something

Usage:
 $scriptname

Options:
 -d   Show debug messages
 -h   Show help
 -v   Show version
"
##

while getopts dhv option
do
    case $option in
        (d) debug ;;
        (h) gettext $help
            exit  ;;
        (v) script_version
            exit  ;;
        (?) exit 2  # indicates "incorrect usage"
    esac
done
shift $((OPTIND - 1))

## MAIN CODE STARTS HERE ##

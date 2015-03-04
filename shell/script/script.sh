#! /usr/bin/env bash

$Revision: 2ad3dcb8d811 $

script=$0
scriptname=$(basename $0)

help="\
\`$scriptname\` does something

Usage:
 $scriptname

Options:
 -d   Show debug messages
 -h   Show help
 -v   Show version
"

source "$(dirname "$0")"/_init.sh

while getopts dhv option
do
    case $option in
        (d) debug ;;
        (h) gettext $help
            exit  ;;
        (v) version
            exit  ;;
        (?) exit 2  # indicates "incorrect usage"
    esac
done
shift $((OPTIND - 1))

## MAIN CODE STARTS HERE ##

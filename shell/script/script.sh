#! /usr/bin/env bash

##
VERSION='$Revision$'
DATE='$Date$'

scriptname=$(basename $0)
help="\
\`$scriptname\` does something

Usage:
 $scriptname

Options:
 -d   show debug messages
 -h   show help
 -v   show version
"
##

script=$0
source "$(dirname "$0")"/_init.sh

while getopts dhv option
do
    case $option in
        d)
            debug
            ;;
        h)
            gethelp
            exit
            ;;
        v)
            getversion
            exit
            ;;
        ?)
            exit 1
    esac
done
shift $((OPTIND - 1))

## MAIN CODE STARTS HERE ##

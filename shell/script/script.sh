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
 -d   show debug messages
 -h   show help
 -v   show version
"
##

while getopts dhv option
do
    case $option in
        (d) debug            ;;
        (h) gethelp;    exit ;;
        (v) getversion; exit ;;
        (?)             exit 1
    esac
done
shift $((OPTIND - 1))

## MAIN CODE STARTS HERE ##

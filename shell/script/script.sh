#! /usr/bin/env bash

$Author: blacktrash $
$Date: 2007/07/17 12:00:47 $
$Header: /tmp/kwdemo.Oz46E2/demo.txt,v 2ad3dcb8d811 2007/07/17 12:00:47 blacktrash $
$Id: demo.txt,v 2ad3dcb8d811 2007/07/17 12:00:47 blacktrash $
$RCSFile: demo.txt,v $
$RCSfile: demo.txt,v $
$Revision: 2ad3dcb8d811 $
$Source: /tmp/kwdemo.Oz46E2/demo.txt,v $

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

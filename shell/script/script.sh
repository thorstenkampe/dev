#! /usr/bin/env bash

VERSION='$Revision$'
DATE='$Date$'

description=              # prints "`SCRIPT` DESCRIPTION"
usage=                    # prints "Usage: SCRIPT USAGE"
options_help=             # prints "Options:\nOPTIONS_HELP"

script=$0
source "$(dirname "$0")"/_init.sh

while getopts dhv option  # option string needs standard options `dhv`
do
    if [[ $option = "?" ]]
    then
        exit 1
    fi
done
shift $((OPTIND - 1))     # remove options from command line

## MAIN CODE STARTS HERE ##

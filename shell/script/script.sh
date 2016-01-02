#! /usr/bin/env bash

VERSION='$Revision$'
DATE='$Date$'

description=             # prints "`SCRIPT` DESCRIPTION"
usage=                   # prints "Usage:\nSCRIPT USAGE"
options_help=            # prints "Options:OPTIONS_HELP"

script=$0
PATH=$(dirname "$script"):$PATH

source _init.sh

while getopts dh option  # option string needs standard options `dh`
do
    if [[ $option == "?" ]]
    then
        exit 1
    fi
done
shift $((OPTIND - 1))    # remove options from command line

## MAIN CODE STARTS HERE ##

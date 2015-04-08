#! /usr/bin/env bash

VERSION='$Revision$'
DATE='$Date$'

description="does something"  # prints "`SCRIPT` DESCRIPTION"
usage="[-O]"                  # prints "Usage: SCRIPT USAGE"
options_help="\
 -O   do optional stuff"      # prints "Options: OPTIONS_HELP"

script=$0
source "$(dirname "$0")"/_init.sh

while getopts O:dhv option    # option string needs standard options `dhv`
do
    case $option in
        O)                    # test if option is set with `if [[ ${opts[O]+set} ]]`
            opts[O]=$OPTARG
            ;;
        \?)
            exit 1
    esac
done
shift $((OPTIND - 1))         # remove options from command line

## MAIN CODE STARTS HERE ##

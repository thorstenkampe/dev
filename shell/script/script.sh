#! /usr/bin/env bash

# INITIALIZATION #
PS4='+$(basename "${BASH_SOURCE[0]}")${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
shopt -os errexit errtrace nounset pipefail
shopt -s dotglob failglob inherit_errexit
export LANG=en_US.UTF-8  # neutral environment

# MAIN CODE STARTS HERE #
function main {
    :
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]
then
    main "$@"
fi

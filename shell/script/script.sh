#! /usr/bin/env bash

# shellcheck disable=SC2154
source "$(/usr/bin/dirname "$0")/toolbox.sh" || exit
tb_init

_params=( "$@" )

# MAIN CODE STARTS HERE #

_usage="
${color[c]}Usage${color[0]}: $(basename "$0") [-l <logfile>]

${color[c]}Options${color[0]}:
  ${color[W]}-l <logfile>${color[0]}  Log to file
  ${color[W]}-h${color[0]}            Show help
  ${color[W]}-d${color[0]}            Show debug and trace messages
"

# shellcheck disable=SC2016
tb_test_args 'which $arg' mailsend-go

if (( ${#false[@]} )); then
    tb_log warn "can't find dependencies: ${false[*]}"
fi

function error_handler {
    tb_log error "command \"$1\" in $2" || true
    #tb_send_mail -to RECIPIENT -sub SUBJECT body -msg MESSAGE || true
}

trap 'error_handler "$BASH_COMMAND" "$(basename "${BASH_SOURCE[0]}")${FUNCNAME:+:${FUNCNAME[0]}}:$LINENO"' err

tb_parse_opts hl:d "$@"
shift $(( OPTIND - 1 ))  # make arguments available as $1, $2...

if tb_set_opt h; then
    echo -en "$_usage"
    exit
fi

if tb_set_opt l; then
    tb_log_to_file "${opts[l]}" bash "$0" "${_params[@]}"
fi

if tb_set_opt d; then
    export verbosity=debug
    if ! shopt -oq xtrace; then
        exec bash -x "$0" "${_params[@]}"
    fi
fi

#! /usr/bin/env bash

# shellcheck disable=SC2154
source "$(/usr/bin/dirname "$0")/toolbox.sh" || exit
tb_init

_params=( "$@" )

# MAIN CODE STARTS HERE #
tb_test_deps mailsend-go

_usage="
${color[c]}Usage${color[0]}: $(basename "$0") [-l <logfile>]

${color[c]}Options${color[0]}:
  ${color[W]}-l <logfile>${color[0]}  Log to file
  ${color[W]}-h${color[0]}            Show help
  ${color[W]}-d${color[0]}            Show debug and trace messages
"

function error_handler {
    # "[ERROR] command "command" in script_name:function_name:line_number"
    tb_log error "command \"$BASH_COMMAND\" in $(basename "${BASH_SOURCE[1]}"):${FUNCNAME[1]}:${BASH_LINENO[0]}" || true
    if ! tb_is_tty; then
        tb_send_mail -to RECIPIENT -sub SUBJECT body -msg MESSAGE || true
    fi
}

trap error_handler err

tb_parse_opts hl:d "$@"
shift $(( OPTIND - 1 ))  # make arguments available as $1, $2...

if [[ -v opts[h] ]]; then
    echo -en "$_usage"
    exit
fi

if [[ -v opts[l] ]]; then
    tb_log_to_file "${opts[l]}" bash "$0" "${_params[@]}"
fi

if [[ -v opts[d] ]]; then
    export verbosity=debug
    if ! shopt -oq xtrace; then
        exec bash -x "$0" "${_params[@]}"
    fi
fi

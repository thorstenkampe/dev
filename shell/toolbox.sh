# shellcheck disable=SC2016,SC2294

## string functions: length: `${#var}`, lower case: `${var,,}`, upper case: `${var^^}`
## absolute path: `readlink|realpath --canonicalize-missing`
## escape characters: `printf %q`
## interactive shell sets `PS1` variable

function tb_is_linux {
    tb_contains "$OSTYPE" linux linux-gnu linux-musl
}

function tb_is_online {
    if   tb_is_linux || [[ -x /usr/bin/ping ]]; then  # POSIX ping
        # `-i` is locale sensitive on Cygwin
        LC_NUMERIC=POSIX ping -c 3 -i 0.2 -s 0 -W 1 8.8.8.8 &> /dev/null
    elif tb_is_windows; then                          # Cygwin but no POSIX ping
        ping -n 3 -l 0 -w 1 8.8.8.8 &> /dev/null
    else
        return 1
    fi
}

function tb_is_tty {
    [[ -t 1 && -t 2 ]]
}

function tb_is_windows {
    tb_contains "$OSTYPE" cygwin msys
}

function tb_join {
    # * https://stackoverflow.com/a/35329275/5740232
    # * https://dev.to/meleu/how-to-join-array-elements-in-a-bash-script-303a
    # * tb_join ';' "${array[@]}"
    local rest=( "${@:3}" )
    printf %s "${2-}" "${rest[@]/#/$1}"
}

function tb_port_reachable {
    {
    if   which ncat; then
        ncat -z --wait 0.024 "$1" "$2"
    elif which nc; then
        nc -z -w 1 "$1" "$2"
    else
        return 1
    fi
    } &> /dev/null
}

function tb_send_mail {
    # https://github.com/muquit/mailsend-go
    # required: `-to`, `-sub`, optional: `body -msg`, `-fname`, `auth -user -pass`
    mailsend-go -smtp localhost -port 25 -from "$(whoami)@$HOSTNAME" "$@"
}

function tb_test_file {
    # test whether file (or folder) satisfies test
    # `tb_test_file file -mmin +60` (test if file is older than sixty minutes)
    [[ $(find "$(dirname "$1")" -mindepth 1 -maxdepth 1 -name "$(basename "$1")" "${@:2}") ]]
}

##
function tb_arc {
    local dest false true split

    tb_parse_opts cx "$@"
    shift $(( OPTIND - 1 ))

    tb_test_args '[[ -v opts[$arg] ]]' c x

    if (( ${#true[@]} != 1 )); then
        tb_log error 'either option "c" (compress) or "x" (extract) must be given'
        return 1
    fi

    if [[ -v opts[c] ]]; then
        tb_split . "$2"

        if [[ ${split[-2]} == tar ]]; then
            tar -caf "$2" -C "$(dirname "$1")" "$(basename "$1")" "${@:3}"
        else
            7za a -ssw "$2" "$(readlink --canonicalize-missing "$1")" "${@:3}"
        fi
    else
        dest=${2-.}  # destination defaults to `.` (current directory)
        tb_split . "$1"

        if [[ ${split[-2]} == tar ]]; then
            tar -xaf "$1" -C "$dest" "${@:3}"
        else
            7za x "$1" -o"$dest" -y "${@:3}"
        fi
    fi
}

function tb_contains {
    # `tb_contains 2 1 2 3 -> true`
    local elem

    for elem in "${@:2}"; do
        if [[ $elem == "$1" ]]; then
            return 0
        fi
    done
    return 1
}

function tb_groupby {
    # `tb_groupby 'echo ${#arg}' 1 22 333 444` -> groupby=([1]=groupby0 [2]=groupby1
    # [3]=groupby2), groupby0=(1), groupby1=(22), groupby2=(333 444)
    #
    # array=${groupby[3]}[@]; echo "${!array}"
    # assemble: `tb_map 'array=$arg[@]; echo "${!array}"' groupby`

    local arg result index i
    declare -gA groupby=()
    i=0

    for arg in "${@:2}"; do
        result=$(eval "$1")
        if [[ -v groupby[$result] ]]; then
            declare -n index=${groupby[$result]}
            index+=( "$arg" )
        else
            # shellcheck disable=SC2178
            declare -n index=groupby$i
            index=( "$arg" )
            groupby[$result]=groupby$((i++))
        fi
    done

    while [[ -v groupby$i ]]; do
        unset groupby$((i++))
    done
}

function tb_init {
    local ps4

    shopt -os errexit errtrace nounset pipefail
    # `inherit_errexit` added in version 4.4
    shopt -s dotglob inherit_errexit 2> /dev/null || true

    if   tb_is_linux; then
        PATH=/usr/local/bin:$PATH

    elif tb_is_windows; then
        PATH=/usr/sbin:/usr/local/bin:/usr/bin:$PATH

        function ps {
            procps "$@"
        }
    fi

    if [[ ! -v BASH_VERSINFO[0] ]]; then
        tb_log warn "unsupported Bash version (current: ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}, minimum: 4.3)"
    fi

    ps4='[TRACE $(basename "${BASH_SOURCE[0]}")${FUNCNAME:+:${FUNCNAME[0]}}:$LINENO]'
    tb_color
    export PS4="${color[C]}$ps4${color[0]} "
    # * https://www.gnu.org/software/gettext/manual/html_node/Locale-Environment-Variables.html
    # * http://pubs.opengroup.org/onlinepubs/7908799/xbd/locale.html
    export LC_ALL=POSIX
}

function tb_log {
    local timestamp
    declare -A loglevel colorlevel
    loglevel=(   [error]=10 [warn]=20 [info]=30 [debug]=40 )
    colorlevel=( [error]=R  [warn]=Y  [info]=W  [debug]=B )

    if tb_is_tty; then
        timestamp=''
    else
        timestamp=" $(date +'%F %T')"
    fi

    if (( ${loglevel[$1]} <= ${loglevel[${verbosity-info}]} )); then
        tb_cecho "${colorlevel[$1]}" "[${1^^}$timestamp] " >&2
        echo -e "${@:2}" >&2
    fi
}

function tb_log_to_file {
    local parent_process
    parent_process=$(ps --pid $PPID --format comm=) || true

    if [[ $parent_process != logsave ]]; then
        exec logsave -a "$1" "${@:2}"
    fi
}

function tb_map {
    # `tb_map 'expr $arg \* 2' array`
    local key arg
    declare -n _array=$2

    for key in "${!_array[@]}"; do
        arg=${_array[$key]}
        _array[$key]=$(eval "$1")
    done
}

function tb_parse_opts {
    unset opts OPTIND
    local opt
    declare -gA opts

    while getopts "$1" opt "${@:2}"; do
        if [[ $opt == '?' ]]; then
            # unknown option or required argument missing
            return 1
        else
            opts[$opt]=${OPTARG-}
        fi
    done
}

function tb_split {
    # * split string into array 'split', e.g. `tb_split : "$PATH"`
    # * https://www.tutorialkart.com/bash-shell-scripting/bash-split-string/
    local string=$2$1
    split=()

    while [[ $string ]]; do
        split+=( "${string%%"$1"*}" )
        string=${string#*"$1"}
    done
}

function tb_test_args {
    # * split arguments into arrays that evaluate to true and to false
    # * `tb_test_args '(( arg % 2 ))' 1 2 3 4` -> true=(1 3) false=(2 4)
    local arg
    true=()
    false=()

    for arg in "${@:2}"; do
        if eval "$1" &> /dev/null; then
            true+=( "$arg" )
        else
            false+=( "$arg" )
        fi
    done
}

function tb_test_deps {
    local false true
    tb_test_args 'which $arg' "$@"

    if (( ${#false[@]} )); then
        tb_log error "can't find dependencies:"
        for dep in "${false[@]}"; do
            tb_cecho sR '✗'
            echo " $dep"
        done
        return 1
    fi
}

# ini #
function tb_section_to_array {
    # -o: store values in section order in ordinary array (omitting keys)
    local section key keys ordered value

    tb_parse_opts o "$@"
    shift $(( OPTIND - 1 ))

    if [[ -v opts[o] ]]; then
        ordered=true
    else
        ordered=false
    fi

    for section in "${@:2}"; do
        unset "$section"
        if ! $ordered; then
            declare -gA "$section"
        fi
        # create array with same name as section name
        declare -n array=$section
        array=()

        mapfile -t keys < <(crudini --get "$1" "$section" 2> /dev/null)
        for key in "${keys[@]}"; do
            value=$(crudini --get "$1" "$section" "$key")
            if $ordered; then
                array+=( "$value" )
            else
                array[$key]=$value
            fi
        done
    done
}

function tb_section_to_var {
    local section

    for section in "${@:2}"; do
        eval "$(crudini --get --format sh "$1" "$section" 2> /dev/null)"
    done
}

# input/output #
function tb_cecho {
    local i char
    tb_color

    for (( i = 0; i < ${#1}; i++ )); do
        char=${1:$i:1}
        if [[ $char == _ ]]; then
            char+=${1:$(( ++i )):1}
        fi
        echo -en "${color[$char]}"
    done
    echo -en "$2${color[0]}"
}

function tb_choice {
    # `tb_choice 'Continue? [Y|n]: ' y n ''`
    # `tb_choice -m $'\nDatabase type [1-5]: ' MSSQL MySQL Oracle PostgreSQL SQLite`
    local PS3 answer

    tb_parse_opts m "$@"
    shift $(( OPTIND - 1 ))  # make arguments available as $1, $2...

    if [[ -v opts[m] ]]; then
        PS3=$1

        select answer in "${@:2}"; do
            if tb_contains "$answer" "${@:2}"; then
                break
            else
                echo 'Selection out of range - please try again' >&2
            fi
        done
    else
        while true; do
            read -erp "$1" answer
            if tb_contains "$answer" "${@:2}"; then
                break
            else
                echo 'Invalid answer - please try again' >&2
            fi
        done
    fi
    echo "$answer"
}

function tb_color {
    # * https://github.com/ppo/bash-colors
    # * https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
    declare -gA color
    # create color alias with `declare -n c=color`
    color=(
        # foreground bright       background    bright
        [k]='\e[30m' [K]='\e[90m' [_k]='\e[40m' [_K]='\e[100m'  # black
        [r]='\e[31m' [R]='\e[91m' [_r]='\e[41m' [_R]='\e[101m'  # red
        [g]='\e[32m' [G]='\e[92m' [_g]='\e[42m' [_G]='\e[102m'  # green
        [y]='\e[33m' [Y]='\e[93m' [_y]='\e[43m' [_Y]='\e[103m'  # yellow
        [b]='\e[34m' [B]='\e[94m' [_b]='\e[44m' [_B]='\e[104m'  # blue
        [m]='\e[35m' [M]='\e[95m' [_m]='\e[45m' [_M]='\e[105m'  # magenta
        [c]='\e[36m' [C]='\e[96m' [_c]='\e[46m' [_C]='\e[106m'  # cyan
        [w]='\e[37m' [W]='\e[97m' [_w]='\e[47m' [_W]='\e[107m'  # white

        # s: bold, d: dim, i: italic, u: underline, U: double-underline, f: blink
        # n: negative, h: hidden, t: strikethrough, 0: reset
        [s]='\e[1m' [d]='\e[2m' [i]='\e[3m' [u]='\e[4m' [U]='\e[21m' [f]='\e[5m'
        [n]='\e[7m' [h]='\e[8m' [t]='\e[9m' [0]='\e[m'
    )

    if ! tb_is_tty; then
        tb_map '' color
    fi
}

function tb_progress {
    # `for item in $(seq 50); do sleep 0.1; echo; done | tb_progress -s 50`
    local pv_opts
    tb_parse_opts s: "$@"
    shift $(( OPTIND - 1 ))

    if [[ -v opts[s] ]]; then
        pv_opts=( "%p (%bof ${opts[s]})  %e" --size "${opts[s]}" )
    else
        pv_opts=( '%p items processed: %b' )
    fi
    pv --interval 0.1 --width 80 --line-mode --format "${pv_opts[@]}" > /dev/null
}

function tb_spinner {
    # `tb_spinner 'sleep 10'`
    # source: https://stackoverflow.com/a/12498305/5740232
    # shellcheck disable=SC1003
    local spin=( '-' '\' '|' '/' )
    local i=0

    eval "$@" &
    # or `kill -0 $! 2> /dev/null` ($! = PID of last job placed into background)
    while [[ -d /proc/$! ]]; do
        echo -en "\r[${spin[(i += 1) % 4]}]" 1>&2
        sleep 0.1
    done
    echo
    wait $!
}

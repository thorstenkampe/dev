# shellcheck disable=SC2016,SC2178,SC2294

## string functions: length: `${#var}`, lower case: `${var,,}`, upper case: `${var^^}`
## absolute path: `readlink|realpath --canonicalize-missing`
## escape characters: `printf %q`
## interactive shell sets `PS1` variable

function tb_get_group {
    # `tb_groupby` helper function (`tb_get_group <groupby_key>`)
    declare -n group=${groupby[$1]}
    echo "${group[@]}"
}

function tb_is_le_version {
    # uses: sort
    # is version1 <= version2 [...]? (`tb_is_le_version 1.5 1.10`)
    printf '%s\n' "$@" | sort --version-sort --check=quiet
}

function tb_is_linux {
    # uses: tb_contains
    tb_contains "$OSTYPE" linux linux-gnu linux-musl
}

function tb_is_online {
    # uses: tb_is_windows
    # uses: ping
    if tb_is_windows && [[ ! -x /usr/bin/ping ]]; then  # Cygwin but no POSIX ping
        ping -n 3 -l 0 -w 1 8.8.8.8 &> /dev/null
    else                                                # POSIX ping
        # `-i` is locale sensitive on Cygwin
        LC_NUMERIC=POSIX ping -c 3 -i 0.2 -s 0 -W 1 8.8.8.8 &> /dev/null
    fi
}

function tb_is_tty {
    [[ -t 1 && -t 2 ]]
}

function tb_is_windows {
    # uses: tb_contains
    tb_contains "$OSTYPE" cygwin msys
}

function tb_join {
    # * https://stackoverflow.com/a/35329275/5740232
    # * https://dev.to/meleu/how-to-join-array-elements-in-a-bash-script-303a
    # * tb_join ';' "${array[@]}"
    local rest=( "${@:3}" )
    printf %s "${2-}" "${rest[@]/#/$1}"
}

function tb_send_mail {
    # uses: mailsend-go, whoami
    # https://github.com/muquit/mailsend-go
    # required: `-to`, `-sub`, optional: `body -msg`, `-fname`, `auth -user -pass`
    mailsend-go -smtp localhost -port 25 -from "$(whoami)@$HOSTNAME" "$@"
}

function tb_test_file {
    # uses: basename, dirname, find
    # test whether file (or folder) satisfies test - uses `find`'s test syntax
    # `tb_test_file file -mmin +60` (test if file was modified more than sixty minutes
    # ago)
    [[ $(find "$(dirname "$1")" -mindepth 1 -maxdepth 1 -name "$(basename "$1")" "${@:2}") ]]
}

function tb_test_port {
    # uses: nc, ncat
    if type -P ncat > /dev/null; then
        ncat -z --wait 0.024 "$1" "$2"
    else
        nc -z -w 1 "$1" "$2" 2> /dev/null
    fi
}

##
function tb_arc {
    # uses: tb_log error, tb_parse_opts, tb_split, tb_test_args
    # uses: 7za, basename, dirname, readlink, tar
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
    # group current directory by file type: `LC_ALL=POSIX tb_groupby 'stat --format %F "$arg"' *`
    # show file types: `printf '%s\n' "${!groupby[@]}"`
    # show regular files: `tb_get_group 'regular file'`
    # assemble: `tb_map 'tb_get_group "$key"' groupby; declare -p groupby`

    local arg result group i
    declare -gA groupby=()
    i=0

    for arg in "${@:2}"; do
        result=$(eval "$1")
        if [[ -v groupby[$result] ]]; then
            declare -n group=${groupby[$result]}
            group+=( "$arg" )
        else
            declare -n group=groupby$i
            group=( "$arg" )
            groupby[$result]=groupby$((i++))
        fi
    done

    while [[ -v groupby$i ]]; do
        unset groupby$((i++))
    done
}

function tb_init {
    # uses: tb_is_le_version, tb_is_linux, tb_is_windows
    # uses: basename, procps
    shopt -os errexit errtrace nounset pipefail
    local bash_version=${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}
    if tb_is_le_version "$bash_version" 4.3 ; then
        echo -e "\e[91m[ERROR]\e[m unsupported Bash version (current: $bash_version, minimum: 4.4)" >&2
        return 1
    fi
    shopt -s dotglob inherit_errexit

    if   tb_is_linux; then
        PATH=/usr/local/bin:$PATH

    elif tb_is_windows; then
        PATH=/usr/sbin:/usr/local/bin:/usr/bin:$PATH

        function ps {
            procps "$@"
        }
    fi

    # * https://www.gnu.org/software/gettext/manual/html_node/Locale-Environment-Variables.html
    # * http://pubs.opengroup.org/onlinepubs/7908799/xbd/locale.html
    export LC_ALL=POSIX \
           PS4='[$(basename "${BASH_SOURCE[0]}")${FUNCNAME:+:${FUNCNAME[0]}}:$LINENO] '
}

function tb_log {
    # uses: tb_color, tb_is_tty
    # uses: date
    local timestamp
    declare -A loglevel=(   [error]=10        [warn]=20           [info]=30          [debug]=40 ) \
               colorlevel=( [error]=brightred [warn]=brightyellow [info]=brightwhite [debug]=brightblue )
    tb_color

    if tb_is_tty; then
        timestamp=''
    else
        timestamp=" $(date +'%F %T')"
    fi

    if (( ${loglevel[$1]} <= ${loglevel[${verbosity-info}]} )); then
        echo -e "${color[${colorlevel[$1]}]}[${1^^}$timestamp]${color[reset]} ${*:2}" >&2
    fi
}

function tb_log_to_file {
    # uses: logsave, ps
    local parent_process
    parent_process=$(ps --pid $PPID --format comm=) || true

    if [[ $parent_process != logsave ]]; then
        exec logsave -a "$1" "${@:2}"
    fi
}

function tb_map {
    # `tb_map 'expr $arg \* 2' array`
    local key arg

    for name in "${@:2}"; do
        declare -n _array=$name

        for key in "${!_array[@]}"; do
            arg=${_array[$key]}
            _array[$key]=$(eval "$1")
        done
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
    # uses: tb_log, tb_test_args
    local false true
    tb_test_args 'type -P "$arg"' "$@"

    if (( ${#false[@]} )); then
        tb_log error "can't find dependencies:"
        error_char="${color[bold]}${color[brightred]}✗${color[reset]}"
        for dep in "${false[@]}"; do
            echo -e "$error_char $dep" >&2
        done
        return 1
    fi
}

# ini #
function tb_section_to_array {
    # uses: tb_parse_opts
    # uses: crudini
    # -o: store values in section order in ordinary array (omitting keys)
    local section key keys value

    tb_parse_opts o "$@"
    shift $(( OPTIND - 1 ))

    for section in "${@:2}"; do
        unset "$section"
        if [[ ! -v opts[o] ]]; then
            declare -gA "$section"
        fi
        # create array with same name as section name
        declare -n _array=$section
        _array=()

        mapfile -t keys < <(crudini --get "$1" "$section" 2> /dev/null)
        for key in "${keys[@]}"; do
            value=$(crudini --get "$1" "$section" "$key")
            if [[ -v opts[o] ]]; then
                _array+=( "$value" )
            else
                _array[$key]=$value
            fi
        done
    done
}

function tb_section_to_var {
    # uses: crudini
    local section

    for section in "${@:2}"; do
        eval "$(crudini --get --format sh "$1" "$section" 2> /dev/null)"
    done
}

# input/output #
function tb_choice {
    # uses: tb_contains, tb_parse_opts
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
    # uses: tb_is_tty, tb_map
    # https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
    # shellcheck disable=SC2034
    declare -gA color=(
        # effects
        [bold]='\e[1m' [dim]='\e[2m' [italic]='\e[3m' [underline]='\e[4m' [double-underline]='\e[21m'
        [blink]='\e[5m' [negative]='\e[7m' [hidden]='\e[8m' [strikethrough]='\e[9m'
        [reset]='\e[m'

        # foreground colors
        [black]='\e[30m' [brightblack]='\e[90m'  [red]='\e[31m'     [brightred]='\e[91m'
        [green]='\e[32m' [brightgreen]='\e[92m'  [yellow]='\e[33m'  [brightyellow]='\e[93m'
        [blue]='\e[34m'  [brightblue]='\e[94m'   [magenta]='\e[35m' [brightmagenta]='\e[95m'
        [cyan]='\e[36m'  [brightcyan]='\e[96m'   [white]='\e[37m'   [brightwhite]='\e[97m'
    ) \
                bcolor=(
        # background colors
        [black]='\e[40m' [brightblack]='\e[100m' [red]='\e[41m'     [brightred]='\e[101m'
        [green]='\e[42m' [brightgreen]='\e[102m' [yellow]='\e[43m'  [brightyellow]='\e[103m'
        [blue]='\e[44m'  [brightblue]='\e[104m'  [magenta]='\e[45m' [brightmagenta]='\e[105m'
        [cyan]='\e[46m'  [brightcyan]='\e[106m'  [white]='\e[47m'   [brightwhite]='\e[107m'
    )

    if ! tb_is_tty; then
        tb_map '' color bcolor
    fi
}

function tb_progress {
    # uses: tb_parse_opts
    # uses: pv
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
    # uses: sleep
    # `tb_spinner 'sleep 10'`
    # source: https://stackoverflow.com/a/12498305/5740232
    # shellcheck disable=SC1003
    local spin=( '-' '\' '|' '/' ) \
          i=0

    eval "$@" &
    # or `kill -0 $! 2> /dev/null` ($! = PID of last job placed into background)
    while [[ -d /proc/$! ]]; do
        echo -en "\r[${spin[(i += 1) % 4]}]" >&2
        sleep 0.1
    done
    echo
    wait $!
}

# shellcheck disable=SC2016,SC2034,SC2164

# relative path -> absolute path
function abspath {
    readlink -m "$1"
}

function curl {
    command curl --silent --show-error --location --connect-timeout 8 "$@"
}

# escape characters in string (!, ", $, ', *, \, `)
function escape {
    printf %q "$1"
}

# escape characters in string for JSON
function escape_json {
    echo "$1" | jq --raw-input @json
}

# (last) extension of file name
function ext {
    echo "${1##*.}"
}

function is_windows {
    [[ $OSTYPE =~ ^(cygwin|msys)$ ]]
}

# length of string
function len {
    echo ${#1}
}

# string to lowercase
function lower {
    echo "${1,,}"
}

# create tmp directory in specified location
function mktempdir {
    mktemp --directory --tmpdir="$1" tmp.XXX
}

# file name without last extension
function name_wo_ext {
    echo "${1%.*}"
}

# nth line of file (`nthline n file` or `... | nthline n`
function nthline {
    awk "BEGIN {rc = 1} NR == $1 {print; rc = 0; exit} END {exit rc}" "${2-}"
}

function second_ext {
    ext "$(name_wo_ext "$1")"
}

# is option set?
function set_opt {
    [[ -v opts[$1] ]]
}

function set_shopt {
    { set -o
      shopt
    } | grep "$1"
}

# split string into array 'splitby', e.g. `splitby : $PATH`
function splitby {
    IFS=$1 read -ra splitby <<< "$2"
}

# create timestamp "yyyy-mm-dd hh:mm:ss"
function timestamp {
    date +'%F %T'
}

# string to uppercase
function upper {
    echo "${1^^}"
}

##
function amap {
    local key arg
    declare -n _array=$2

    for key in "${!_array[@]}"; do
        arg=${_array[$key]}
        _array[$key]=$(eval "$1")
    done
}

function arc {
    local dest

    parse_opts cx "$@"
    shift $(( OPTIND - 1 ))

    # shellcheck disable=SC2016
    test_args 'set_opt $arg' c x

    if (( ${#true[@]} != 1 )); then
        log error 'either option "c" (compress) or "x" (extract) must be given'
        return 1
    fi

    if set_opt c; then
        if [[ $(second_ext "$2") == tar ]]; then
            tar -caf "$2" -C "$(dirname "$1")" "$(basename "$1")" "${@:3}"
        else
            7za a -ssw "$2" "$(abspath "$1")" "${@:3}"
        fi
    else
        dest=${2-.}  # destination defaults to `.` (current directory)

        if [[ $(second_ext "$1") == tar ]]; then
            tar -xaf "$1" -C "$dest" "${@:3}"
        else
            7za x "$1" -o"$dest" -y "${@:3}"
        fi
    fi
}

# `choice 'Continue? [Y|n]: ' y n ''`
function choice {
    local answer true
    true=()

    until (( ${#true[@]} )); do
        read -erp "$1" answer
        test_args '[[ $arg == $answer ]]' "${@:2}"
    done

    echo "$answer"
}

# `select_from $'\nDatabase type [1-5]: ' MSSQL MySQL Oracle PostgreSQL SQLite`
function select_from {
    local PS3 answer true
    PS3=$1

    select answer in "${@:2}"; do
        test_args '[[ $arg == $answer ]]' "${@:2}"
        if (( ${#true[@]} )); then
            echo "$answer"
            break
        else
            echo 'Selection out of range - please try again' 1>&2
        fi
    done
}

function init {
    shopt -os errexit errtrace nounset pipefail
    shopt -s dotglob failglob inherit_errexit 2> /dev/null || true

    PS4='+$(basename "${BASH_SOURCE[0]}")${FUNCNAME:+:$FUNCNAME}[$LINENO]: '

    if is_windows; then
        PATH=/usr/sbin:/usr/local/bin:/usr/bin:$PATH

        function ps {
            procps "$@"
        }
    fi
}

function install_pkg {
    case $(ext "$1") in
        (deb)
            dpkg --install --refuse-downgrade --skip-same-version "$1"
            ;;

        (rpm)
            # https://serverfault.com/questions/880398/yum-install-local-rpm-throws-error-if-up-to-date
            yum install --assumeyes "$1" || true
            ;;

        (gz)
            arc -x "$1" "$2"            \
                   --keep-newer-files   \
                   --no-same-owner      \
                   --strip-components 1 \
                   --verbose            \
                   --wildcards          \
                   "$3"
            ;;

        (zip)
            arc -x "$1" "$2"
            ;;

        (*)
            cp --verbose --force "$1" "$2"
            chmod +x "$2"

    esac
}

# * https://stackoverflow.com/a/35329275/5740232
# * https://dev.to/meleu/how-to-join-array-elements-in-a-bash-script-303a
# * joinby ';' "${array[@]}"
function joinby {
    local rest=( "${@:3}" )
    printf %s "${2-}" "${rest[@]/#/$1}"
    echo
}

function log {
    declare -A loglevel colorcode
    loglevel=( [error]=10 [warn]=20 [info]=30 [debug]=40 )

    if [[ ! -v loglevel[$1] ]]; then
        echo "ERROR: log level \"$1\" not defined"
        return 1
    fi

    if [[ -t 2 ]]; then
        # color codes: http://en.wikipedia.org/wiki/ANSI_escape_code#Colors
        colorcode=( [error]='\e[1;31m' [warn]='\e[1;33m' [info]='\e[1;37m' [debug]='\e[1;34m' [reset]='\e[m' )
    else
        colorcode=( [error]='' [warn]='' [info]='' [debug]='' [reset]='' )
    fi

    if (( ${loglevel[$1]} <= ${loglevel[${verbosity-warn}]} )); then
        echo -e "${colorcode[$1]}[$(upper "$1") $(timestamp)]${colorcode[reset]}" "${@:2}" >&2
    fi
}

function log_to_file {
    local parent_process
    parent_process=$(ps --pid $PPID --format comm=) || true

    if [[ $parent_process != logsave ]]; then
        exec logsave -a "$1" "${@:2}"
    fi
}

function parse_opts {
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

# https://github.com/muquit/mailsend-go
# required: `-to`, `-sub`, optional: `body -msg`, `-fname`, `auth -user -pass`
function send_mail {
    mailsend-go -smtp localhost -port 25    \
                -from "$(whoami)@$HOSTNAME" \
                "$@"
}

# * split arguments into arrays that evaluate to true and to false
# * `test_args '(( arg % 2 ))' 1 2 3 4` -> true=(1 3) false=(2 4)
# * same as above: `test_args 'expr $arg % 2' ...`
function test_args {
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

# test whether file (or folder) satisfies test
# `test_file file -mmin +60` (test if file is older than sixty minutes)
function test_file {
    local path name
    path=$(dirname "$1")
    name=$(basename "$1")

    [[ $(find "$path" -mindepth 1 -maxdepth 1 -name "$name" "${@:2}") ]]
}

function vartype {
    case $(declare -p "$1") in
        (declare\ -a*)
            echo array
            ;;

        (declare\ -A*)
            echo 'associative array'
            ;;

        (declare\ -i*)
            echo integer
            ;;

        (*)
            echo string
    esac
}

# ini #
function has_section {
    crudini --get "$@" &> /dev/null
}

function section_to_array {
    # -o: store values in section order in ordinary array (omitting keys)
    local section key keys value

    parse_opts o "$@"
    shift $(( OPTIND - 1 ))

    for section in "${@:2}"; do
        unset "$section"
        if ! set_opt o; then
            declare -gA "$section"
        fi
        # create array with same name as section name
        declare -n array=$section
        array=()

        if has_section "$1" "$section"; then
            mapfile -t keys < <(crudini --get "$1" "$section")
            for key in "${keys[@]}"; do
                value=$(crudini --get "$1" "$section" "$key")
                if set_opt o; then
                    array+=( "$value" )
                else
                    array[$key]=$value
                fi
            done
        fi
    done
}

function section_to_var {
    local section

    for section in "${@:2}"; do
        if has_section "$1" "$section"; then
            eval "$(crudini --get --format sh "$1" "$section")"
        fi
    done
}

# progress #
# `spinner 'sleep 10'`
# taken from https://stackoverflow.com/a/12498305/5740232
function spinner {
    local spin i
    # shellcheck disable=SC1003
    spin=('-' '\' '|' '/')
    i=0

    eval "$@" &

    # or `kill -0 $! 2> /dev/null` ($! = PID of last job placed into background)
    while [[ -d /proc/$! ]]; do
        echo -en "\r[${spin[(i += 1) % 4]}]"
        sleep 0.1
    done

    echo
    wait $!
}

# `for item in $(seq 50); do sleep 0.1; echo; done | progressbar -s 50`
function progressbar {
    parse_opts s: "$@"
    shift $(( OPTIND - 1 ))

    if set_opt s; then
        pv --size "${opts[s]}" --interval 0.1 --width 80 --line-mode --format "%p (%bof ${opts[s]})  %e" > /dev/null
    else
        pv --interval 0.1 --width 80 --line-mode --format '%p items processed: %b' > /dev/null
    fi
}

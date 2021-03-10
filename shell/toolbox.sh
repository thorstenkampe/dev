# shellcheck disable=SC2034,SC2164

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

function is_sourced {
    [[ ${BASH_SOURCE[0]} != "$0" ]]
}

function is_windows {
    [[ $OSTYPE =~ ^(cygwin|msys)$ ]]
}

# length of string
function len {
    echo ${#1}
}

# string to lowercase
function lowercase {
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
function uppercase {
    echo "${1^^}"
}

##
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
            arcx "$1" "$2"            \
                 --keep-newer-files   \
                 --no-same-owner      \
                 --strip-components 1 \
                 --verbose            \
                 --wildcards          \
                 "$3"
            ;;

        (zip)
            arcx "$1" "$2"
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
    declare -A loglevel
    loglevel=( [ERROR]=10 [WARNING]=20 [INFO]=30 [DEBUG]=40 )
    verbosity=${verbosity-WARNING}

    if (( loglevel[$1] <= loglevel[$verbosity] )); then
        echo -e "$1": "${@:2}" >&2
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

# archive #
function arcc {
    local first_ext
    first_ext=$(ext "$(name_wo_ext "$2")")

    if [[ $first_ext == tar ]]; then
        tar -caf "$2" -C "$(dirname "$1")" "$(basename "$1")" "${@:3}"
    else
        7za a -ssw "$2" "$(abspath "$1")" "${@:3}"
    fi
}

function arcx {
    local first_ext dest
    first_ext=$(ext "$(name_wo_ext "$1")")
    dest=${2-.}  # destination defaults to `.` (current directory)

    if [[ $first_ext == tar ]]; then
        tar -xaf "$1" -C "$dest" "${@:3}"
    else
        7za x "$1" -o"$dest" -y '*' "${@:3}"
    fi
}

# ini #
function has_ini {
    crudini --get "$@" &> /dev/null
}

function section_to_array {
    # arrays are ordered
    local section key keys

    for section in "${@:2}"; do
        # create array with same name as section name
        declare -n array=$section
        array=()

        if has_ini "$1" "$section"; then
            mapfile -t keys < <(crudini --get "$1" "$section")
            for key in "${keys[@]}"; do
                array+=("$(crudini --get "$1" "$section" "$key")")
            done
        fi
    done
}

function section_to_dict {
    # associative arrays are unordered
    local section key keys

    for section in "${@:2}"; do
        # create associative array with same name as section name
        declare -gA "$section"
        declare -n dict=$section
        dict=()

        if has_ini "$1" "$section"; then
            mapfile -t keys < <(crudini --get "$1" "$section")
            for key in "${keys[@]}"; do
                dict[$key]=$(crudini --get "$1" "$section" "$key")
            done
        fi
    done
}

function section_to_var {
    local section

    for section in "${@:2}"; do
        if has_ini "$1" "$section"; then
            eval "$(crudini --get --format sh "$1" "$section")"
        fi
    done
}

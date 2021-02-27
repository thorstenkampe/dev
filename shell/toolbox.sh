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
    awk "NR == $1" "${2-}"
}

# is option set?
function set_opt {
    [[ -v opts[$1] ]]
}

function set_shopt {
    set -o
    shopt
}

# show arguments line by line surrounded by "»«"
function showargs {
    printf '»%s«\n' "$@"
}

# split string into array 'splitby', e.g. `splitby : $PATH`
function splitby {
    IFS=$1 read -ra splitby <<< "$2"
}

# create timestamp "yyyy-mm-dd hh:mm:ss"
function timestamp {
    date +'%F %T'
}

# create timestamp suitable as filename on Windows
function timestamp_file {
    local timestamp
    timestamp=$(timestamp)
    echo "${timestamp//:/-}"
}

# string to uppercase
function uppercase {
    echo "${1^^}"
}

##
# * https://docs.github.com/en/rest/reference/rate-limit
# * https://python.gotrained.com/search-github-api/
# * https://blogs.infosupport.com/accessing-githubs-rest-api-with-curl/
function github_api_conns {
    local api_url
    api_url=https://api.github.com/rate_limit

    echo -n 'anonymous: '
    curl $api_url | jq .resources.core.remaining

    echo -n 'authenticated: '
    curl --user "$GITHUB_PUBLIC_TOKEN:x-oauth-basic" $api_url | jq .resources.core.remaining
}

# `groupby 'type -t $arg' ls cd vi groupby` ->
# groupby=([file]="ls" [function]="groupby" [alias]="vi" [builtin]="cd")
function groupby {
    local arg key
    declare -Ag groupby
    groupby=()

    for arg in "${@:2}"; do
        key=$(eval "$1" 2> /dev/null) || true
        key=${key:-None}
        groupby[$key]+="$(escape "$arg") "
    done

    for key in "${!groupby[@]}"; do
        groupby[$key]=${groupby[$key]% }
    done
}

function init {
    shopt -os errexit errtrace nounset pipefail
    shopt -s dotglob failglob inherit_errexit 2> /dev/null || true

    PS4='+$(basename "${BASH_SOURCE[0]}")${FUNCNAME:+:$FUNCNAME}[$LINENO]: '

    if is_windows; then
        PATH=/usr/sbin:/usr/bin:$PATH

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
    local rest
    rest=( "${@:3}" )
    printf %s "${2-}" "${rest[@]/#/$1}"
    echo
}

function log {
    declare -A loglevel
    loglevel=( [ERROR]=10 [WARNING]=20 [INFO]=30 [DEBUG]=40 )
    verbosity=${verbosity-WARNING}

    if (( loglevel[$1] <= loglevel[$verbosity] )); then
        echo -e "$1": "$2" >&2
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

# pretty print associative array by name (`pprint assoc`)
function pprint {
    declare -a keyval
    declare -n _assarr=$1
    local key value

    for key in "${!_assarr[@]}"; do
        value=${_assarr[$key]}
        keyval+=( "$key: ${value:-''}" )
    done

    joinby ', ' "${keyval[@]}"
}

# example: `showopts a:bd: -a 1 -b -c -d`
function showopts {
    local opt opt_type opt_types
    unset OPTIND
    opt_types=(valid_opts unknown_opts arg_missing)
    declare -a valid_opts unknown_opts arg_missing

    while getopts ":$1" opt "${@:2}"; do
        if [[ $opt == '?' ]]; then
            unknown_opts+=( "-$OPTARG" )

        elif [[ $opt == : ]]; then
            arg_missing+=( "-$OPTARG" )

        else
            if [[ -v OPTARG ]]; then
                valid_opts+=( "-$opt=$OPTARG" )
            else
                valid_opts+=( "-$opt" )
            fi
        fi
    done

    for opt_type in "${opt_types[@]}"; do
        declare -n type=$opt_type

        if (( ${#type[@]} )); then
            echo -n "${opt_type/_/ }: "
            joinby ', ' "${type[@]}"
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

# archive #
function arcc {
    local source name parent

    if [[ $(ext "$2") == zip ]]; then
        source=$(abspath "$1")

        7za a -ssw "$2" "$source" "${@:3}"

    else
        name=$(basename "$1")
        parent=$(dirname "$1")

        tar -caf "$2" -C "$parent" "$name" "${@:3}"
    fi
}

function arcx {
    if [[ $(ext "$1") == zip ]]; then
        7za x "$1" -o"$2" -y '*' "${@:3}"

    else
        tar -xaf "$1" -C "$2" "${@:3}"
    fi
}

function zipc {
    local target name parent
    target=$(abspath "$2")
    name=$(basename "$1")
    parent=$(dirname "$1")

    cd "$parent"
    zip -qry "$target" "$name" "${@:3}"
    cd "$OLDPWD"
}

function zipx {
    # ${@:3}: files to extract from archive (no options)
    unzip -qo "$1" -d "$2" "${@:3}"
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
        declare -n array="$section"
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
        declare -n dict="$section"
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

# redis #
function has_redis {
    redis-cli ping &> /dev/null
}

function cache_exists {
    [[ $(redis-cli exists "$1") =~ 1 ]]
}

function cache_get {
    redis-cli get "$1"
}

# $1: key, $2: value, $3: expiration in seconds
function cache_set {
    if [[ -v 3 ]]; then
        redis-cli set "$1" "$2" ex "$3" > /dev/null
    else
        redis-cli set "$1" "$2" > /dev/null
    fi
}

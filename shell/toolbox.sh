# shellcheck disable=SC2164

function abspath {
    readlink -m "$1"
}

function escape {
    printf '%q' "$1"
}

function ext {
    echo "${1##*.}"
}

function len {
    echo ${#1}
}

function set_opt {
    [[ -v opts[$1] ]]
}

function showargs {
    printf '»%s«\n' "$@"
}

function splitby {
    # split string into array 'split', e.g. `splitby : $PATH`
    # shellcheck disable=SC2034
    IFS=$1 read -ra split <<< "$2"
}

function timestamp {
    # replace colons for file name on Windows: `ts=$(timestamp); ${ts//:/-}`
    date +'%F %T'
}

function groupby {
    # `groupby 'type -t $arg' ls cd vi groupby` ->
    # groups=([file]="ls" [function]="groupby" [alias]="vi" [builtin]="cd")
    local arg key value
    declare -Ag groups
    groups=()

    for arg in "${@:2}"; do
        value=$(eval "$1" 2> /dev/null || true)
        value=${value:-None}
        groups[$value]+="$(escape "$arg") "
    done

    for key in "${!groups[@]}"; do
        groups[$key]=${groups[$key]% }
    done
}

# * https://stackoverflow.com/a/35329275/5740232
# * https://dev.to/meleu/how-to-join-array-elements-in-a-bash-script-303a
function joinby {
    # joinby ';' "${array[@]}"
    local rest=( "${@:3}" )
    printf '%s' "${2-}" "${rest[@]/#/$1}"
    echo
}

function log {
    declare -A loglevel
    loglevel=( [CRITICAL]=10 [ERROR]=20 [WARNING]=30 [INFO]=40 [DEBUG]=50 )
    verbosity=${verbosity-WARNING}

    if (( loglevel[$1] <= loglevel[$verbosity] )); then
        echo -e "$1": "$2" >&2
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

function pprint {
    # pretty print associative array by name (`pprint assoc`)
    declare -a keyval
    declare -n _assarr=$1
    local key value

    for key in "${!_assarr[@]}"; do
        value=${_assarr[$key]}
        keyval+=( "$key: ${value:-''}" )
    done

    joinby ', ' "${keyval[@]}"
}

function showopts {
    # example: `showopts a:bd: -a 1 -b -c -d`

    local opt_type opt_types
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

        if [[ ${type[*]} ]]; then
            echo -n "${opt_type/_/ }: "
            joinby ', ' "${type[@]}"
        fi
    done
}

function test_args {
    # split arguments into arrays that evaluate to true and to false
    # `test_args '(( arg % 2 ))' 1 2 3 4` -> true=(1 3) false=(2 4)
    #  same as above: `test_args 'expr $arg % 2' ...`
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

function test_file {
    # test whether file (or folder) satisfies test
    # `test_file file -mmin +60` (test if file is older than sixty minutes)

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
        7za x "$1" -o"$2" '*' "${@:3}"

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

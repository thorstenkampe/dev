# shellcheck disable=SC2164

function is_windows {
    [[ $OSTYPE =~ ^(cygwin|msys)$ ]]
}

if is_windows; then
    PATH=/usr/sbin:/usr/bin:$PATH

    function ps {
        procps "$@"
    }
fi

# MAIN CODE STARTS HERE #

function abspath {
    readlink -m "$1"
}

function arcc {
    local name parent
    name=$(basename "$1")
    parent=$(dirname "$1")

    if [[ $(ext "$2") == zip ]]; then
        cd "$parent"
        zip -qry "$(abspath $2)" "$name" "${@:3}"
        # shellcheck disable=SC2103
        cd -

    else
        # use archive suffix to determine compression program
        tar -acf "$2" -C "$parent" "$name" "${@:3}"

    fi
}

function arcx {
    if [[ $(ext "$1") == zip ]]; then
        # ${@:3}: files to extract from archive (no options)
        unzip -qo "$1" -d "$2" "${@:3}"

    else
        # use archive suffix to determine compression program
        tar -axf "$1" -C "$2" "${@:3}"

    fi
}

function ext {
    echo "${1##*.}"
}

function is_file_older {
    # `$1`: file to check, `$2`: age in minutes
    local path name
    path=$(dirname "$1")
    name=$(basename "$1")
    [[ $(find "$path" -mmin +"$2" -name "$name") ]]
}

# * https://stackoverflow.com/a/35329275/5740232
# * https://dev.to/meleu/how-to-join-array-elements-in-a-bash-script-303a
function join_by {
    # join_by ';' "${array[@]}"
    local rest=( "${@:3}" )
    printf '%s' "${2-}" "${rest[@]/#/$1}"
    echo
}

function log {
    declare -A loglevel=( [CRITICAL]=10 [ERROR]=20 [WARNING]=30 [INFO]=40 [DEBUG]=50 )

    if (( loglevel[$1] <= loglevel[${verbosity-WARNING}] )); then
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
    local key

    for key in "${!_assarr[@]}"; do
        keyval+=( "$key: ${_assarr[$key]:-''}" )
    done

    join_by ', ' "${keyval[@]}"
}

function set_opt {
    [[ -v opts[$1] ]]
}

function showargs {
    printf '>%s<\n' "$@"
}

function showopts {
    # example: `showopts a:bd: -a 1 -b -c -d`
    unset OPTIND
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

    if [[ ${valid_opts[*]} ]]; then
        echo -n 'valid opts: '
        join_by ', ' "${valid_opts[@]}"
    fi

    if [[ ${unknown_opts[*]} ]]; then
        echo -n 'unknown opts: '
        join_by ', ' "${unknown_opts[@]}"
    fi

    if [[ ${arg_missing[*]} ]]; then
        echo -n 'arg missing: '
        join_by ', ' "${arg_missing[@]}"
    fi
}

function showpath {
    split_by ':' "$PATH"
    showargs "${split[@]}"
}

function split_by {
    # e.g. `split_by ':' $PATH`
    # shellcheck disable=SC2034
    IFS=$1 read -ra split <<< "$2"
}

function test_arguments {
    # test if all arguments satisfy test
    # `test_arguments '(( arg >= 3 ))' 3 4`
    if (( $# <= 1 )); then
        return 1
    else
        local arg
        # shellcheck disable=SC2034
        for arg in "${@:2}"; do
            if ! eval "$1"; then
                return 1
            fi
        done
    fi
}

function timestamp {
    # replace colons for file name on Windows: `ts=$(timestamp); ${ts//:/-}`
    date +'%F %T'
}

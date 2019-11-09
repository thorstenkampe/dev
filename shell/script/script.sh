help='Usage: script.sh'

# INITIALIZATION #
PS4='+$(basename "${BASH_SOURCE[0]}")${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
shopt -os nounset pipefail errexit
export LANG=en_US.UTF-8  # neutral environment

# OPTIONS #
function do_options {
    while getopts h option
    do
        case $option in
            (h)
                echo "$help"
                exit;;

            ('?')
                exit 1
        esac
    done
    shift $((OPTIND - 1))  # remove options from command line
}

# MAIN CODE STARTS HERE #
if [[ ${BASH_SOURCE[0]} == "$0" ]]
then
    do_options "$@"
fi

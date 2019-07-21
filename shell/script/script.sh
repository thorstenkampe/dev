# HELP #
help='Usage: script.sh'

# INITIALIZATION #
PS4='+$(basename $BASH_SOURCE)${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
shopt -os nounset pipefail errexit
IFS=''                   # disable word splitting
export LANG=en_US.UTF-8  # neutral environment

# DEFAULT OPTIONS #
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

# MAIN CODE STARTS HERE #

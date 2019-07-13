help='SCRIPT DESCRIPTION

Usage:
 SCRIPT [options]

Options:
 -h   show help
 -d   show debug messages'

# INITIALIZATION #
shopt -os nounset pipefail errexit
IFS=  # disable word splitting
# https://www.gnu.org/software/gettext/manual/html_node/Locale-Environment-Variables.html
export LANG=en_US.UTF-8  # "neutral" environment

# LOGGING #
# modeled after Python modules `logging` and `colorlog`
verbosity=WARNING  # default level
declare -A loglevel colorcodes
loglevel=([CRITICAL]=50 [ERROR]=40 [WARNING]=30 [INFO]=20 [DEBUG]=10)
# for color codes see http://en.wikipedia.org/wiki/ANSI_escape_code#Colors
# CRITICAL: brightred, ERROR: red, WARNING: yellow, INFO: green, DEBUG: white)
colorcodes=([CRITICAL]='1;31' [ERROR]='0;31' [WARNING]='0;33' [INFO]='0;32' [DEBUG]='0;37')

function log {
    if ((loglevel[$1] >= loglevel[$verbosity]))
    then
        if [[ -t 2 ]]  # only output color if stderr is attached to tty
        then
            echo -e "\e[${colorcodes[$1]}m$1\e[m: $2"
        else
            echo "$1: $2"
        fi > /dev/stderr
    fi
}

# DEFAULT OPTIONS #
function default_options {
    case $option in
        (h)
            echo "$help"
            exit;;

        (d)
            PS4='+$(basename $BASH_SOURCE)${FUNCNAME:+:$FUNCNAME}[$LINENO]: '
            verbosity=DEBUG

            log DEBUG "bash $BASH_VERSION"
            shopt -os xtrace;;

        ('?')
            exit 1
    esac
}

# MAIN CODE STARTS HERE #
while getopts hd option
do
    default_options
done
shift $((OPTIND - 1))  # remove options from command line

#! /usr/bin/env python

"""
{script} does something

Usage:
 {script} [-d]

Options:
 -d, --debug     show debug messages
 -h, --help      show help
 -v, --version   show version
"""

import _init, docopt

arguments = docopt.docopt(_(__doc__.format(script = _init.scriptname)),
                          version = _init.version_msg)

_init.setupdebugging(arguments['--debug'])

def main():
    ##region MAIN CODE STARTS HERE ##
    pass
    #endregion

main()

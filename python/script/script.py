#! /usr/bin/env python

"""
`SCRIPT` DESCRIPTION

Usage:
 SCRIPT [-d]

Options:
 -d, --debug     show debug messages
 -h, --help      show help
"""

from __future__ import division, print_function, unicode_literals
import sys, docopt
sys.dont_write_bytecode = True
import _init

arguments = docopt.docopt(_(__doc__))

_init.setup_win_unicode_console()
_init.setupdebugging(arguments['--debug'])

##region MAIN CODE STARTS HERE ##
def main():
    pass

main()
#endregion

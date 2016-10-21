#! /usr/bin/env python

"""
`SCRIPT` DESCRIPTION

Usage:
 SCRIPT [options]

Options:
 -h, --help   show help
"""

from __future__ import division, print_function, unicode_literals
import sys, docopt
sys.dont_write_bytecode = True
import _init

arguments = docopt.docopt(_(__doc__))

_init.setup_win_unicode_console()

##region MAIN CODE STARTS HERE ##
def main():
    pass

main()
#endregion

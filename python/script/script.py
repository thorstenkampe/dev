#! /usr/bin/env python

#region
"""
`{script}` does something

Usage:
 {script} [-d]

Options:
 -d, --debug     show debug messages
 -h, --help      show help
 -v, --version   show version
"""

from __future__ import division, print_function, unicode_literals
import _init, docopt

arguments = docopt.docopt(
                (__doc__.format(script = _init.scriptname)),
                version = _init.version_msg)

_init.setupdebugging(arguments['--debug'])
#endregion

def main():
    ## MAIN CODE STARTS HERE ##
    pass

main()

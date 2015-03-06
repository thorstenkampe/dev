#! /usr/bin/env python

##region START ##
"""
`{script}` does something

Usage:
 {script} [-d]

Options:
 -d, --debug     show debug messages
 -h, --help      show help
 -v, --version   show version
"""

# For Python2
from __future__ import division, print_function, unicode_literals

__version__ = '$Revision$'
__date__    = '$Date$'

import _init, docopt

arguments = docopt.docopt(_(__doc__.format(script = _init.scriptname)),
                          version = _init.version(__version__, __date__))

# Debugging should be always available
_init.setupdebugging(arguments['--debug'])
#endregion

def main():
    ## MAIN CODE STARTS HERE ##
    pass

main()

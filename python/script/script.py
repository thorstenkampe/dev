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

from __future__ import division, print_function, unicode_literals

# no byte compiled files (`.pyc`, `.pyo`, or `__pycache__`)
import sys
sys.dont_write_bytecode = True

import _init, docopt

__version__ = '$Revision$'
__date__    = '$Date$'

_init.setup_win_unicode_console()

arguments = docopt.docopt(_(__doc__.format(script = _init.scriptname)),
                          version = _init.version(_init.scriptname,
                                                  __version__,
                                                  __date__))

# Debugging should always be available
_init.setupdebugging(arguments['--debug'], __version__, __date__)

# make logging available without module prefix
logger  = _init.logger
logging = _init.logging
#endregion

##region MAIN CODE STARTS HERE ##
def main():
    pass

if __name__ == '__main__':
    main()
#endregion

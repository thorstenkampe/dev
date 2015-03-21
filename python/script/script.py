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
import _init, docopt

__version__ = '$Revision$'
__date__    = '$Date$'

arguments = docopt.docopt(_(__doc__.format(script = _init.scriptname)),
                          version = _init.version(_init.scriptname,
                                                  __version__,
                                                  __date__))

# Debugging should always be available
_init.setupdebugging(arguments['--debug'], __version__, __date__)
#endregion

##region MAIN CODE STARTS HERE ##
def main():
    pass

main()
#endregion

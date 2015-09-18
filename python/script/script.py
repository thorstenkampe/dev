#! /usr/bin/env python

##region START ##
from __future__ import division, print_function, unicode_literals

description  = ''  # prints "`SCRIPT` DESCRIPTION"
usage        = ''  # prints "Usage:\nSCRIPT [-d] USAGE"
options_help = ''  # prints "Options:OPTIONS_HELP"

__version__  = '$Revision$'
__date__     = '$Date$'

# no byte compiled files (`.pyc`, `.pyo`, or `__pycache__`)
import sys
sys.dont_write_bytecode = True

import _init, docopt

arguments = docopt.docopt(_(_init.help.format(description  = description,
                                              usage        = usage,
                                              options_help = options_help)),
                          version = _init.version(_init.scriptname,
                                                  __version__,
                                                  __date__))

_init.setup_win_unicode_console()
_init.setupdebugging(arguments['--debug'], __version__, __date__)
#endregion

##region MAIN CODE STARTS HERE ##
def main():
    pass

if __name__ == '__main__':
    main()
#endregion

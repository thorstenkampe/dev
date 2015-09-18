#! /usr/bin/env python

from __future__ import division, print_function, unicode_literals
import sys
sys.dont_write_bytecode = True
import _init, docopt

description  = ''  # prints "`SCRIPT` DESCRIPTION"
usage        = ''  # prints "Usage:\nSCRIPT [-d] USAGE"
options_help = ''  # prints "Options:OPTIONS_HELP"

__version__  = '$Revision$'
__date__     = '$Date$'

arguments = docopt.docopt(_(_init.help.format(description  = description,
                                              usage        = usage,
                                              options_help = options_help)),
                          version = _init.version(_init.scriptname,
                                                  __version__,
                                                  __date__))

_init.setup_win_unicode_console()
_init.setupdebugging(arguments['--debug'], __version__, __date__)

##region MAIN CODE STARTS HERE ##
def main():
    pass

main()
#endregion

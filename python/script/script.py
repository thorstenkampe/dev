#! /usr/bin/env python

"""
SCRIPT DESCRIPTION

Usage:
 SCRIPT [-h|-d]

Options:
 -h, --help    show help
 -d, --debug   show debug messages
"""

import sys
sys.dont_write_bytecode = True
import docpie, _init

class MyPie(docpie.Docpie):
    usage_name  = _('Usage:')
    option_name = _('Options:')

arguments = MyPie(_(__doc__)).docpie()
_init.setdebug(arguments['--debug'])

#region MAIN CODE STARTS HERE #
# needs `def main()` for debugging

#endregion

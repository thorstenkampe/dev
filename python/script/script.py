#! /usr/bin/env python3

"""
`SCRIPT` DESCRIPTION

Usage:
 SCRIPT [options]

Options:
 -h, --help   show help
"""

import sys; sys.dont_write_bytecode = True
import docpie, _init

class MyPie(docpie.Docpie):
    usage_name  = _('Usage:')
    option_name = _('Options:')

arguments = MyPie(_(__doc__)).docpie()

##region MAIN CODE STARTS HERE ##
#endregion

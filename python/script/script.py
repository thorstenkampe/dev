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
import _init, docopt, npyscreen

__version__ = '$Revision$'
__date__    = '$Date: Thu, 05 Mar 2015 15:26:15 +0100 $'

arguments = docopt.docopt(_(__doc__.format(script = _init.scriptname)),
                          version = '{script} {version} ({date})'.format(
                                        script  = _init.scriptname,
                                        version = __version__[11:-2],
                                        date    = __date__[7:-2]))

_init.setupdebugging(arguments['--debug'])
#endregion

def main():
    ## MAIN CODE STARTS HERE ##

    def input(*args):
        npyscreen.notify_wait('Enter text on next screen',
                              title = 'INFORMATION')

        MyForm = npyscreen.Form(name = 'Enter text')
        text   = MyForm.add(npyscreen.TitleText,
                            name  = 'Text:',
                            value = 'boilerplate_text')
        MyForm.edit()
        return text.value

    # `npyscreen` interferes with tracing: indentation,
    # broken trace on Windows, no trace after `wrapper_basic()` on Linux
    print(npyscreen.wrapper_basic(input))

main()

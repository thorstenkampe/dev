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

    # setting debug  mode via `-d` will activate debug statements in
    # `sarge` and `pysftp`

    #
    import sarge
    sarge.get_stdout('ssh -V')

    # Using Paramiko for authentication with `Pageant` or `ssh-agent`
    # for key in paramiko.agent.Agent().get_keys():
    #     try: [connect with key]
    #     except paramiko.AuthenticationException: pass
    #     else: break

    #
    import pysftp

    connection = pysftp.Connection('test.rebex.net',
                                   username = 'demo',
                                   password = 'password')

main()
#endregion

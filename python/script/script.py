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
#endregion

main()

##region REFERENCE ##
# - File and directory access: https://docs.python.org/3/library/filesys.html
#
# - Directory and file operations: https://docs.python.org/3/library/shutil.html
#   copy, copytree, rmtree, move, make_archive, unpack_archive
#
# - Compressed files and archives: https://docs.python.org/3/library/archiving.html
#   gzip, bz2, xz, zip, tar
#
# - Files and directories: https://docs.python.org/3/library/os.html#os-file-dir
#   chdir, mkdir, remove, rmdir, symlink
#
#   Wrapper - Unipath: https://github.com/mikeorr/Unipath
#   also look at https://github.com/mikeorr/Unipath#comparision-with-osospathshutil-and-pathpy
#
# - subprocess: https://docs.python.org/3/library/subprocess.html
#   call, check_call, check_output
#
#   Wrapper - Sarge: http://sarge.readthedocs.org/en/latest/
#
# - Paramiko: http://docs.paramiko.org/
#     - Chapter 5, SSH in "Python for Unix and Linux System
#       Administration"
#     - examples in the package archive
#
#   Wrappers:
#     - scpclient: https://bitbucket.org/ericvsmith/scpclient
#     - pysftp: https://bitbucket.org/dundeemt/pysftp
#     - openssh-wrapper: https://github.com/NetAngels/openssh-wrapper
#endregion

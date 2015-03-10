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

##region REFERENCE ##
# - File and directory access:
#   https://docs.python.org/3/library/filesys.html
#
# - Directory and file operations (copy, copytree, rmtree, move,
#   make_archive, unpack_archive):
#   https://docs.python.org/3/library/shutil.html
#
# - Compressed files and archives (gzip, bz2, xz, zip, tar):
#   https://docs.python.org/3/library/archiving.html
#
# - Files and directories (chdir, mkdir, remove, rmdir, symlink):
#   https://docs.python.org/3/library/os.html#os-file-dir
#
# Siehe auch https://github.com/mikeorr/Unipath#comparision-with-osospathshutil-and-pathpy
#
#  - SSH (Paramiko): http://docs.paramiko.org/
#endregion

##region MAIN CODE STARTS HERE ##
def main():
    pass
#endregion

main()

##region START ##
# $Revision$
# $Date$
from __future__ import division, print_function, unicode_literals

import sys, os
#endregion

##region VARIABLES ##
scriptpath = os.path.dirname(sys.argv[0])
scriptname = os.path.basename(sys.argv[0])
#endregion

##region IMPORTS ##
import logging, colorama, colorlog   ## LOGGING
import traceback, colored_traceback  ## TRACEBACK
import gettext                       ## INTERNATIONALIZATION
import inspect, platform             ## DEBUGGING
#endregion

##region LOGGING ##
colorama.init()

logger  = logging.getLogger()
handler = logging.StreamHandler()

# Python2 does not support `style = '{'` in `[Colored]Formatter`
handler.setFormatter(colorlog.ColoredFormatter(
    '%(log_color)s%(levelname)s:%(reset)s %(message)s'))

logging.getLogger().addHandler(handler)
#endregion

##region TRACEBACK ##
def _notraceback(type, value, trace_back):
    logger.critical(
        ''.join(traceback.format_exception_only(type, value)).rstrip())

# During standard execution of script, we want no tracebacks for the
# user, just an exception
sys.excepthook = _notraceback

if os.getenv('DEBUG') is not None:
    # enable tracebacks for internal development
    colored_traceback.add_hook()
#endregion

##region INTERNATIONALIZATION ##
gettext.install(
    scriptname, localedir = os.path.join(scriptpath, '_translations'))
#endregion

##region DEBUGGING ##
def _traceit(frame, event, arg):
    if (frame.f_globals['__name__'] == '__main__' and
        event in ['call', 'line']):

        logger.debug('+[{lineno}]: {code}'.format(
            lineno = frame.f_lineno,
            code   = inspect.getframeinfo(frame).code_context[0].rstrip()))
    return _traceit

# OS version
if sys.platform == 'win32':
    os_platform = 'Windows {release}'.format(
                      release = platform.release())

elif sys.platform.startswith('linux'):
    os_platform = '{distribution}'.format(
                      distribution = ' '.join(platform.linux_distribution()[:2]))

elif sys.platform == 'cygwin':
    os_platform = 'Cygwin {release}'.format(
                      release = platform.release()[:6])

elif sys.platform == 'darwin':
    os_platform = 'OSX {release}'.format(
                      release = platform.mac_ver()[0])

# enable debugging for main script
def setupdebugging(debug):
    if debug is True:
        logger.setLevel(logging.DEBUG)
        sys.settrace(_traceit)

    logger.debug('Python {version} on {platform}'.format(
        version  = platform.python_version(),
        platform = os_platform))
#endregion

##region VERSION ##
def version(revision, date):
    return '{script} {version} ({date})'.format(
               script  = scriptname,
               version = revision[11:-2],
               date    = date[7:-2])
#endregion

##region IMPORTS ##
from __future__ import division, print_function, unicode_literals
import sys                                         # VARIABLES
import signal, sys                                 # CONSOLE
import colorama, colorlog, logging                 # LOGGING
import gettext, locale                             # INTERNATIONALIZATION
import colored_traceback, inspect, locale          # DEBUGGING
import logging, os, platform, sys, traceback       # DEBUGGING
import concurrent.futures, progress.spinner, time  # SPINNER

# VARIABLES, INTERNATIONALIZATION
try:
    import pathlib
except ImportError:
    import pathlib2 as pathlib
#endregion

##region VARIABLES ##
scriptpath    = pathlib.Path(sys.argv[0]).parent
scriptname    = pathlib.Path(sys.argv[0]).name

isPyinstaller = getattr(sys, 'frozen', None) == True
isPython2     = sys.version_info.major < 3
isCygwin      = sys.platform == 'cygwin'
isLinux       = sys.platform.startswith('linux')
isOSX         = sys.platform == 'darwin'
isWindows     = sys.platform == 'win32'
#endregion

##region CONSOLE ##
# no traceback on Ctrl-C;
# cleaning up on termination can be done with `atexit.register()`
if isWindows:  # Windows has no `SIGHUP`
    termsignals = (signal.SIGINT, signal.SIGTERM)
else:
    termsignals = (signal.SIGINT, signal.SIGTERM, signal.SIGHUP)

for termsignal in termsignals:
    signal.signal(termsignal, lambda *args: sys.exit())
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

##region INTERNATIONALIZATION ##
# `str()` superfluous in Python3
gettext.install(
    scriptname, localedir = str(pathlib.Path(scriptpath, '_translations')))

# make Python locale aware
locale.setlocale(locale.LC_ALL, '')
#endregion

##region DEBUGGING ##
# OS version
if isWindows:
    os_platform = ['Windows', platform.release()]

elif isLinux:
    os_platform = platform.linux_distribution()[:2]

elif isCygwin:
    os_platform = ['Cygwin', platform.release()[:5]]

elif isOSX:
    os_platform = ['OSX', platform.mac_ver()[0]]

os_platform = ' '.join(os_platform)

def _notraceback(type, value, trace_back):
    logger.critical(
        ''.join(traceback.format_exception_only(type, value)).rstrip())

def _traceit(frame, event, arg):
    if (frame.f_globals['__name__'] == '__main__' and
        event in ['call', 'line']):

        logger.debug('+[{lineno}]: {code}'.format(
            lineno = frame.f_lineno,
            code   = inspect.getframeinfo(frame).code_context[0].rstrip()))
    return _traceit

# During standard execution, we want no traceback, just the exception
sys.excepthook = _notraceback

# enable debugging for main script
if os.getenv('PYTHONDEBUG') is not None:
    logger.setLevel(logging.DEBUG)

    # enable (colored) tracebacks
    colored_traceback.add_hook()

    if not (isPyinstaller and isLinux):
        sys.settrace(_traceit)

logger.debug('Python %s %s on %s', platform.python_version(),
                platform.architecture()[0], os_platform)
locale_vars = {key: os.environ.get(key, '') for key in
                   ('LANGUAGE', 'LC_ALL', 'LANG')}
locale_vars['decimal_point'] = locale.localeconv()['decimal_point']
logger.debug(locale_vars)
#endregion

##region SPINNER ##
def show_spinner(*args):

    spinner  = progress.spinner.Spinner()
    executor = concurrent.futures.ThreadPoolExecutor(max_workers = 1)
    future   = executor.submit(*args)
    # Python2 backport `pythonfutures` needs a delay after
    # `executor.submit()` for `future.running()`
    time.sleep(0.001)

    while future.running():
        spinner.next()
        time.sleep(0.1)

    executor.shutdown()
    spinner.finish()
    print()
#endregion

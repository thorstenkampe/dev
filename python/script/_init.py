##region IMPORTS ##
from __future__ import division, print_function, unicode_literals
import sys                                         # VARIABLES
import signal                                      # CONSOLE
import logging, colorama, colorlog                 # LOGGING
import sys, os, traceback, colored_traceback       # TRACEBACK
import gettext                                     # INTERNATIONALIZATION
import sys, inspect, platform                      # DEBUGGING
import time, progress.spinner, concurrent.futures  # SPINNER

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
isPy2exe      = getattr(sys, 'frozen', None) == 'console_exe'

isPython2     = sys.version_info.major < 3

isCygwin      = sys.platform == 'cygwin'
isLinux       = sys.platform.startswith('linux')
isOSX         = sys.platform == 'darwin'
isWindows     = sys.platform == 'win32'

help = '''
`{script}` {{description}}

Usage:
 {script} [-d] {{usage}}

Options:{{options_help}}
 -d, --debug     show debug messages
 -h, --help      show help
'''.format(script = scriptname)
#endregion

##region CONSOLE ##
# no traceback on Ctrl-C;
# cleaning up on termination can be done with `atexit.register()`
if isWindows:  # Windows has no `SIGHUP`
    termsignals = signal.SIGINT, signal.SIGTERM
else:
    termsignals = signal.SIGINT, signal.SIGTERM, signal.SIGHUP

for termsignal in termsignals:
    signal.signal(termsignal, lambda *args: sys.exit())

def setup_win_unicode_console():
    # still issues on Cygwin with Python3
    if isWindows and not isPy2exe:
        import win_unicode_console
        win_unicode_console.enable()
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
# `str()` superfluous in Python3
gettext.install(
    scriptname, localedir = str(pathlib.Path(scriptpath, '_translations')))
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
if isWindows:
    os_platform = ['Windows', platform.release()]

elif isLinux:
    os_platform = platform.linux_distribution()[:2]

elif isCygwin:
    os_platform = ['Cygwin', platform.release()[:5]]

elif isOSX:
    os_platform = ['OSX', platform.mac_ver()[0]]

os_platform = ' '.join(os_platform)

# enable debugging for main script
def setupdebugging(debug):
    if debug is True:
        logger.setLevel(logging.DEBUG)
        if isPyinstaller:
            # under PyInstaller we have no trace with `_traceit`, so
            # we want at least (colored) tracebacks
            colored_traceback.add_hook()
        else:
            sys.settrace(_traceit)

    logger.debug(' '.join(['Python', platform.python_version(),
                           platform.architecture()[0], 'on', os_platform]))
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

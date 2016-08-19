##region IMPORTS ##
from __future__ import division, print_function, unicode_literals
import sys, os                                     # VARIABLES
import signal                                      # CONSOLE
import logging, colorama, colorlog                 # LOGGING
import sys, os, traceback, colored_traceback       # TRACEBACK
import os, gettext                                 # INTERNATIONALIZATION
import sys, inspect, platform                      # DEBUGGING
import time, progress.spinner, concurrent.futures  # SPINNER
#endregion

##region VARIABLES ##
__version__   = '$Revision$'
__date__      = '$Date$'

scriptpath    = os.path.dirname(sys.argv[0])
scriptname    = os.path.basename(sys.argv[0])

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

THIS SOFTWARE COMES WITHOUT WARRANTY, LIABILITY, OR SUPPORT!
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
if isWindows:
    os_platform = 'Windows {release}'.format(
                      release = platform.release())

elif isLinux:
    os_platform = '{distribution}'.format(
                      distribution = ' '.join(platform.linux_distribution()[:2]))

elif isCygwin:
    os_platform = 'Cygwin {release}'.format(
                      release = platform.release()[:5])

elif isOSX:
    os_platform = 'OSX {release}'.format(
                      release = platform.mac_ver()[0])

# enable debugging for main script
def setupdebugging(debug, script_version, script_date):
    if debug is True:
        logger.setLevel(logging.DEBUG)
        if isPyinstaller:
            # under PyInstaller we have no trace with `_traceit`, so
            # we want at least (colored) tracebacks
            colored_traceback.add_hook()
        else:
            sys.settrace(_traceit)

    logger.debug(version(scriptname, script_version, script_date))

    logger.debug(version('_init.py', __version__, __date__))

    logger.debug('Python {version} {arch} on {platform}'.format(
        version  = platform.python_version(),
        arch     = platform.architecture()[0],
        platform = os_platform))
#endregion

##region VERSION ##
def version(file, revision, date):
    return '{script} {version} ({date})'.format(
               script  = file,
               version = revision[11:-2],
               date    = date[7:-2])
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

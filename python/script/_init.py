## region VARIABLES ##
import sys, os

script        = sys.argv[0]
scriptpath    = os.path.dirname(script)
scriptname    = os.path.basename(script)

isPython2     = sys.version_info.major == 2
isPyInstaller = getattr(sys, 'frozen', None)
#endregion

## region IMPORTS ##

# before importing we check for external module dependencies
import imp
try:
    import importlib.util
except ImportError:
    pass

modules   = ['colorama', 'colorlog', 'crcmod', 'docopt']
not_found = []
modulemsg = (
'Required external module(s) not found! You can install the package(s) with...',
'',
'pip install [--target "{scriptpath}"] {module}'
)

for module in modules:

    try:
        if importlib.util.find_spec(module) is None:
            not_found.append(module)
    except (AttributeError, NameError):  # fallback for Python2 and Python3 < 3.4
        try:
            imp.find_module(module)
        except ImportError:
            not_found.append(module)

# PyInstaller includes all dependencies
if not_found and not isPyInstaller:
    sys.exit('\n'.join(modulemsg).format(scriptpath = scriptpath,
                                         module     = " ".join(not_found)))

import logging, colorama, colorlog       ## LOGGING
import traceback                         ## TRACEBACK
import gettext                           ## INTERNATIONALIZATION
import inspect                           ## DEBUGGING
import binascii, time, crcmod, platform  ## VERSION
#endregion

## region LOGGING ##
colorama.init()

logger  = logging.getLogger()
handler = logging.StreamHandler()
if isPython2:
    logmsg = '%(log_color)s%(levelname)s:%(reset)s %(message)s'
else:
    logmsg = '{log_color}{levelname}:{reset} {message}'

handler.setFormatter(colorlog.ColoredFormatter(logmsg, style = '{'))
logger.addHandler(handler)

# set default log level to `info` so info messages can be seen
logger.setLevel(logging.INFO)
#endregion

## region TRACEBACK ##
def _notraceback(type, value, trace_back):
    logger.critical(''.join(traceback.format_exception_only(type, value)).rstrip())

# no tracebacks, just the exception on error
sys.excepthook = _notraceback

if os.getenv('DEBUG') is not None:
    # enable tracebacks for internal development
    try:
        import colored_traceback.auto
    except ImportError:
        logger.info('Install `colored_traceback` for colored tracebacks')
#endregion

## region INTERNATIONALIZATION ##
gettext.install(scriptname, localedir = os.path.join(scriptpath, '_translations'))
#endregion

## region DEBUGGING ##
def _traceit(frame, event, arg):
    tracemsg = '+[{lineno}]: {code}'

    if (frame.f_globals['__name__'] == '__main__' and
        event in ['call', 'line']):

        code_context = inspect.getframeinfo(frame).code_context[0].rstrip()

        logger.debug(tracemsg.format(lineno = frame.f_lineno,
                                     code   = code_context))

    return _traceit

def setupdebugging(debug):
    if debug is True:
        logger.setLevel(logging.DEBUG)
        sys.settrace(_traceit)
#endregion

## region VERSION ##
# Script version
# version is DATE.TIME.CHECKSUM (YYMMDD.HHMM_UTC.CRC-8_HEX)
version_msg       = '{scriptname} {date}.{time}.{crc:02x} (Python {version} on {platform})'
modification_time = time.gmtime(os.path.getmtime(script))
version_date      = time.strftime('%y%m%d', modification_time)
version_time      = time.strftime('%H%M', modification_time)

scriptfile        = open(script, 'rb').read()

# OS version
if sys.platform == 'win32':
    os_platform = 'Windows {release}'.format(release = platform.release())

elif sys.platform.startswith('linux'):
    os_platform = '{distribution}'.format(distribution = ' '.join(platform.linux_distribution()[:2]))

elif sys.platform == 'cygwin':
    os_platform = 'Cygwin {release}'.format(release = platform.release()[:6])

elif sys.platform == 'darwin':
    os_platform = 'OSX {release}'.format(release = platform.mac_ver()[0])

#
version_msg = version_msg.format(scriptname = scriptname,
                                 date       = version_date,
                                 time       = version_time,
                                 crc        = crcmod.predefined.mkCrcFun('crc-8')(scriptfile),
                                 version    = platform.python_version(),
                                 platform   = os_platform)
#endregion

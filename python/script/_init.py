from __future__ import (
    division, print_function, unicode_literals)
import sys, os

##region VARIABLES ##
script     = sys.argv[0]
scriptpath = os.path.dirname(script)
scriptname = os.path.basename(script)
#endregion

##region IMPORTS ##
try:
    import logging, colorama, colorlog               ## LOGGING
    import traceback, colored_traceback              ## TRACEBACK
    import gettext                                   ## INTERNATIONALIZATION
    import inspect, platform, pkg_resources, docopt  ## DEBUGGING
    import time, crcmod                              ## VERSION
except ImportError as exception:
    sys.exit(
'ERROR: {exception}\n'
'`{script}` needs external modules `colorama`, `colorlog`, `docopt`, and `crcmod`.'.format(
        exception = exception,
        script    = scriptname))
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

# no tracebacks, just the exception on error
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

def setupdebugging(debug):
    if debug is True:
        logger.setLevel(logging.DEBUG)
        sys.settrace(_traceit)

    logger.debug('Python {version} {arch} on {platform}'.format(
        version  = platform.python_version(),
        arch     = platform.architecture()[0],
        platform = os_platform))

    logger.debug('{module_versions}'.format(
                     module_versions = ', '.join(modules)))

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

# module versions
modules = ['colorama', 'colorlog', 'crcmod', 'docopt', 'colored_traceback']

for index, module in enumerate(modules):
    try:
        modules[index] += ' {version}'.format(
                              version = pkg_resources.get_distribution(module).version)
    except pkg_resources.DistributionNotFound:
        try:
            modules[index] += ' {version}'.format(
                                  version = sys.modules[module].__version__)
        except AttributeError:
            pass
#endregion

##region VERSION ##
# version is MODIFICATION_DATE.TIME.FILE_CHECKSUM (YYMMDD.HHMM_UTC.CRC-8_HEX)
version_msg = '{scriptname} {datetime}.{crc:02x}'.format(
    scriptname = scriptname,
    datetime   = time.strftime('%y%m%d.%H%M',
                     time.gmtime(os.path.getmtime(script))),
    crc        = crcmod.predefined.mkCrcFun('crc-8')(
                     open(script, 'rb').read()))
#endregion

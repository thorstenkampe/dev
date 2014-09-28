from __future__ import division, print_function, unicode_literals
import sys, os

##region VARIABLES ##
script     = sys.argv[0]
scriptpath = os.path.dirname(script)
scriptname = os.path.basename(script)
#endregion

##region IMPORTS ##
try:
    import logging, colorama, colorlog  ## LOGGING
    import traceback                    ## TRACEBACK
    import gettext                      ## INTERNATIONALIZATION
    import inspect                      ## DEBUGGING
    import time, crcmod                 ## VERSION
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

# set default log level to `info` so info messages can be seen
logger.setLevel(logging.INFO)
#endregion

##region TRACEBACK ##
def _notraceback(type, value, trace_back):
    logger.critical(
        ''.join(traceback.format_exception_only(type, value)).rstrip())

# no tracebacks, just the exception on error
sys.excepthook = _notraceback

if os.getenv('DEBUG') is not None:
    try:
        # enable tracebacks for internal development
        import colored_traceback.auto
    except ImportError:
        logger.info(
            'Install `colored_traceback` for colored tracebacks')
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

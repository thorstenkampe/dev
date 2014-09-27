from __future__ import division, print_function, unicode_literals
import sys, os

##region VARIABLES ##
script     = sys.argv[0]
scriptpath = os.path.dirname(script)
scriptname = os.path.basename(script)
#endregion

##region IMPORTS ##
modulemsg = """\
ERROR: {exception}
`{script}` needs external module `{module}`.
You can install the missing package with...
`pip install [--target "{scriptpath}"] {module}`
"""

try:
    import logging, colorama, colorlog  ## LOGGING
    import traceback                    ## TRACEBACK
    import gettext                      ## INTERNATIONALIZATION
    import inspect                      ## DEBUGGING
    import binascii, time, crcmod       ## VERSION

except ImportError as exception:
    sys.exit(modulemsg.format(exception  = exception,
                              script     = scriptname,
                              scriptpath = scriptpath,
                              module     = str(exception).split()[-1].strip("'")))
#endregion

##region LOGGING ##
logmsg = '%(log_color)s%(levelname)s:%(reset)s %(message)s'

colorama.init()

logger  = logging.getLogger()
handler = logging.StreamHandler()
# Python2 does not support `style = '{')` in `[Colored]Formatter` (for `logmsg`)
handler.setFormatter(colorlog.ColoredFormatter(logmsg))
logger.addHandler(handler)

# set default log level to `info` so info messages can be seen
logger.setLevel(logging.INFO)
#endregion

##region TRACEBACK ##
def _notraceback(type, value, trace_back):
    logger.critical(''.join(traceback.format_exception_only(type, value)).rstrip())

# no tracebacks, just the exception on error
sys.excepthook = _notraceback

if os.getenv('DEBUG') is not None:
    try:
        # enable tracebacks for internal development
        import colored_traceback.auto
    except ImportError:
        logger.info('Install `colored_traceback` for colored tracebacks')
#endregion

##region INTERNATIONALIZATION ##
gettext.install(scriptname, localedir = os.path.join(scriptpath, '_translations'))
#endregion

##region DEBUGGING ##
tracemsg = '+[{lineno}]: {code}'

def _traceit(frame, event, arg):
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

##region VERSION ##
# version is DATE.TIME.CHECKSUM (YYMMDD.HHMM_UTC.CRC-8_HEX)
version_msg       = '{scriptname} {date}.{time}.{crc:02x}'
modification_time = time.gmtime(os.path.getmtime(script))
version_date      = time.strftime('%y%m%d', modification_time)
version_time      = time.strftime('%H%M', modification_time)

scriptfile        = open(script, 'rb').read()

version_msg       = version_msg.format(scriptname = scriptname,
                                       date       = version_date,
                                       time       = version_time,
                                       crc        = crcmod.predefined.mkCrcFun('crc-8')(scriptfile))
#endregion

##region CONSOLE ##
import signal, sys; from pycompat import system

# cleaning up on termination can be done with `atexit.register()`
def error_handler(signum, frame):
    termsignal = signal.Signals(signum).name
    logger.error(f'received {termsignal} signal, exiting...')
    sys.exit(1)

# Windows has no `SIGHUP` and `SIGQUIT` and `SIGTERM` is a NOOP
# (https://bugs.python.org/issue26350)
if system.is_windows:
    termsignals = (signal.SIGINT, signal.SIGBREAK)
else:
    termsignals = (signal.SIGINT, signal.SIGTERM, signal.SIGHUP,
                   signal.SIGQUIT)

for termsignal in termsignals:
    signal.signal(termsignal, error_handler)
#endregion

##region LOGGING ##
import colorlog

logger  = colorlog.getLogger()
handler = colorlog.StreamHandler()

handler.setFormatter(colorlog.ColoredFormatter(
    '%(log_color)s%(levelname)s:%(reset)s %(message)s'))

logger.addHandler(handler)
#endregion

##region INTERNATIONALIZATION ##
import gettext, locale, pathlib, sys

script = pathlib.Path(sys.argv[0])

gettext.install(
    script.name, localedir = str(pathlib.Path(script.parent, '_translations')))

# make Python locale aware
locale.setlocale(locale.LC_ALL, '')
#endregion

##region DEBUGGING ##
import inspect, locale, os, platform, sys, traceback

def _notraceback(type, value, trace_back):
    logger.critical(
        ''.join(traceback.format_exception_only(type, value)).rstrip())

def _traceit(frame, event, arg):
    if (frame.f_globals['__name__'] == '__main__' and
        event in ['call', 'line']):

        logger.debug('+[%s]: %s', frame.f_lineno,
            inspect.getframeinfo(frame).code_context[0].rstrip())
    return _traceit

# during standard execution, we want no traceback, just the exception
sys.excepthook = _notraceback

# enable debugging for main script
if os.getenv('PYTHONDEBUG') is not None:
    logger.setLevel('DEBUG')
    sys.settrace(_traceit)

logger.debug('Python %s %s', platform.python_version(), platform.architecture()[0])
locale_vars = {key: os.getenv(key, '') for key in
                   ('LANGUAGE', 'LC_ALL', 'LANG')}
locale_vars['decimal_point'] = locale.localeconv()['decimal_point']
logger.debug(locale_vars)
#endregion

#! /usr/bin/env python

"""
SCRIPT DESCRIPTION

Usage:
 SCRIPT [-h|-d]

Options:
 -h, --help    show help
 -d, --debug   show debug messages
"""

#region IMPORTS #
import gettext, inspect, locale, os, pathlib, platform, signal, sys, traceback
import colorlog, docpie
from pycompat import system
#endregion

#region TRAPS #
# exit handler can be done with `atexit.register()`
def error_handler(signum, frame):
    termsignal = signal.Signals(signum).name
    logger.error('received %s signal, exiting...', termsignal)
    sys.exit(1)

# Windows has no `SIGHUP` and `SIGQUIT`, `SIGTERM` is a NOOP
# (https://bugs.python.org/issue26350)
if system.is_windows:
    termsignals = signal.SIGINT, signal.SIGBREAK
else:
    termsignals = signal.SIGINT, signal.SIGTERM, signal.SIGHUP, signal.SIGQUIT

for termsignal in termsignals:
    signal.signal(termsignal, error_handler)
#endregion

#region LOGGING #
logger  = colorlog.getLogger(name = '__main__')
handler = colorlog.StreamHandler()

handler.setFormatter(colorlog.ColoredFormatter(
    '%(log_color)s%(levelname)s:%(reset)s %(message)s'))

logger.addHandler(handler)
#endregion

#region INTERNATIONALIZATION #
script = pathlib.Path(sys.argv[0])

gettext.install(
    script.name, localedir = pathlib.Path(script.parent, '_translations'))

# make Python locale aware
locale.setlocale(locale.LC_ALL, '')
#endregion

#region TRACEBACK #
def _notraceback(type_, value, trace_back):
    logger.critical(
        ''.join(traceback.format_exception_only(type_, value)).rstrip())

sys.excepthook = _notraceback  # we want no traceback, just the exception
#endregion

#region DEBUGGING #
def _traceit(frame, event, arg):
    if frame.f_globals['__name__'] == '__main__' and event in ['call', 'line']:

        logger.debug('+[%s]: %s', frame.f_lineno,
                     inspect.getframeinfo(frame).code_context[0].rstrip())
    return _traceit

def _debug():
    logger.setLevel('DEBUG')

    logger.debug(
        'Python %s %s', platform.python_version(), platform.architecture()[0])
    locale_vars = {key: os.getenv(key, '') for key in ('LANGUAGE', 'LC_ALL', 'LANG')}
    locale_vars['decimal_point'] = locale.localeconv()['decimal_point']
    logger.debug(locale_vars)

    sys.settrace(_traceit)
#endregion

#region OPTIONS #
class MyPie(docpie.Docpie):
    usage_name  = _('Usage:')
    option_name = _('Options:')

arguments = MyPie(_(__doc__)).docpie()
if arguments['--debug']:
    _debug()
#endregion

#region MAIN CODE STARTS HERE #
# needs `def main()` for debugging

#endregion

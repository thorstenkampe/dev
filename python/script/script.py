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
#endregion

#region TRAPS #
# exit handler can be done with `atexit.register()`
def error_handler(signum, frame):
    logger.error('received %s signal, exiting...', signal.Signals(signum).name)
    sys.exit(1)

# `SIGTERM` is a NOOP on Windows (https://bugs.python.org/issue26350)
for termsignal in signal.SIGINT, signal.SIGTERM:
    signal.signal(termsignal, error_handler)
#endregion

#region LOGGING #
logger  = colorlog.getLogger(name = '__main__')
handler = colorlog.StreamHandler()

handler.setFormatter(colorlog.ColoredFormatter(
    '%(log_color)s%(levelname)s%(reset)s: %(message)s'))

logger.addHandler(handler)
#endregion

#region INTERNATIONALIZATION #
script = pathlib.Path(sys.argv[0])

gettext.install(
    script.name, localedir = pathlib.Path(script.parent, '_translations'))

# make Python locale aware - `locale.localeconv()` too see values
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
    logger.debug(
        {key: os.getenv(key, '') for key in ('LANGUAGE', 'LC_ALL', 'LANG')})

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

"""
SCRIPT DESCRIPTION

Usage:
 SCRIPT [-h|-d]

Options:
 -h, --help    show help
 -d, --debug   show debug messages
"""

# IMPORTS #
import inspect, platform, signal, sys, traceback
import colorlog, docpie

# TRAPS #
# exit handler can be done with `atexit.register()`
def error_handler(signum, frame):
    logger.error('received %s signal, exiting...', signal.Signals(signum).name)
    sys.exit(1)

# `SIGTERM` is a NOOP on Windows (https://bugs.python.org/issue26350)
for termsignal in signal.SIGINT, signal.SIGTERM:
    signal.signal(termsignal, error_handler)

# LOGGING #
logger  = colorlog.getLogger(name = '__main__')
handler = colorlog.StreamHandler()

handler.setFormatter(colorlog.ColoredFormatter(
    '%(log_color)s%(levelname)s%(reset)s: %(message)s'))

logger.addHandler(handler)

# TRACEBACK #
def _notraceback(type_, value, trace_back):
    logger.critical(
        ''.join(traceback.format_exception_only(type_, value)).rstrip())

sys.excepthook = _notraceback  # we want no traceback, just the exception

# DEBUGGING #
def _traceit(frame, event, arg):
    if frame.f_globals['__name__'] == '__main__' and event in ['call', 'line']:

        logger.debug('+[%s]: %s', frame.f_lineno,
                     inspect.getframeinfo(frame).code_context[0].rstrip())
    return _traceit

def _debug():
    logger.setLevel('DEBUG')

    logger.debug(
        'Python %s %s', platform.python_version(), platform.architecture()[0])

    sys.settrace(_traceit)

# OPTIONS #
arguments = docpie.docpie(__doc__)
if arguments['--debug']:
    _debug()

# MAIN CODE STARTS HERE #
# needs `def main()` for debugging

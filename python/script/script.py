"""
SCRIPT DESCRIPTION

Usage:
 SCRIPT [-h|-d]

Options:
 -h, --help    show help
 -d, --debug   show debug messages
"""

# INITIALIZATION #
import inspect, platform, sys, traceback
import colorlog, docpie

# LOGGING #
logger  = colorlog.getLogger(name = '__main__')
handler = colorlog.StreamHandler()
log_msg = '%(log_color)s%(levelname)s%(reset)s: %(message)s'

handler.setFormatter(colorlog.ColoredFormatter(log_msg))
logger.addHandler(handler)

# DEBUGGING #
def _notraceback(type_, value, trace_back):
    exception = ''.join(traceback.format_exception_only(type_, value)).rstrip()
    logger.critical(exception)

def _traceit(frame, event, arg):
    if frame.f_globals['__name__'] == '__main__' and event in ['call', 'line']:
        trace_msg = inspect.getframeinfo(frame).code_context[0].rstrip()
        logger.debug('+[%s]: %s', frame.f_lineno, trace_msg)
    return _traceit

def _debug():
    logger.setLevel('DEBUG')
    logger.debug('Python %s %s', platform.python_version(), platform.architecture()[0])
    sys.settrace(_traceit)

sys.excepthook = _notraceback  # we want no traceback, just the exception

# DEFAULT OPTIONS #
arguments = docpie.docpie(__doc__)

if arguments['--debug']:
    _debug()

# MAIN CODE STARTS HERE #
def main():
    pass

main()

"""
SCRIPT DESCRIPTION

Usage:
 SCRIPT [-h|-d]

Options:
 -h, --help    show help
 -d, --debug   show debug messages
"""

import inspect, sys, colorlog, docpie

# LOGGING #
logger  = colorlog.getLogger(name = '__main__')
handler = colorlog.StreamHandler()

handler.setFormatter(colorlog.ColoredFormatter('%(log_color)s%(levelname)s%(reset)s: %(message)s'))
logger.addHandler(handler)

# DEBUGGING #
def _traceit(frame, event, arg):
    if frame.f_globals['__name__'] == '__main__' and event in ['call', 'line']:
        logger.debug('+[%s]: %s', frame.f_lineno, inspect.getframeinfo(frame).code_context[0].rstrip())
    return _traceit

def _debug():
    logger.setLevel('DEBUG')
    sys.settrace(_traceit)

# DEFAULT OPTIONS #
arguments = docpie.docpie(__doc__)

if arguments['--debug']:
    _debug()

# MAIN CODE STARTS HERE #
def main():
    pass

main()

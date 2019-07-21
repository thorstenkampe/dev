"""
Usage: script.py
"""

import colorlog, docpie

# LOGGING #
logger  = colorlog.getLogger(name = '__main__')
handler = colorlog.StreamHandler()

handler.setFormatter(colorlog.ColoredFormatter('%(log_color)s%(levelname)s%(reset)s: %(message)s'))
logger.addHandler(handler)

# OPTIONS #
arguments = docpie.docpie(__doc__)

# MAIN CODE STARTS HERE #

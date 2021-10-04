import os, sys
import click, click_help_colors
from loguru import logger
from rich   import traceback

traceback.install(width=80, extra_lines=1)

if os.isatty(2):
    timestamp = ''
else:
    timestamp = ' {time:YYYY-MM-DD HH:mm:ss}'
logfmt = f'<level>[{{level}}{timestamp}]</> {{message}}\n'

def configure_logging(level, fmt=logfmt):
    logger.configure(handlers=[dict(sink=sys.stderr, level=level.upper(), format=fmt)])

configure_logging(level='info')

@click.command(
    context_settings   = {'help_option_names': ['-h', '--help']},
    cls                = click_help_colors.HelpColorsCommand,
    help_headers_color = 'cyan',         # NOSONAR
    help_options_color = 'bright_white'  # NOSONAR
)

# MAIN CODE STARTS HERE #

def main():
    '''purpose of script'''

main()

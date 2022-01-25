import os, sys
import click, click_help_colors, rich.traceback
from loguru import logger
import toolbox as tb

rich.traceback.install(width=80, extra_lines=1)

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

@click.option(
    '-d', '--debug', is_flag=True, help='Show debug and trace messages.'
)

# MAIN CODE STARTS HERE #

def main(debug):
    '''purpose of script'''

    if debug:
        configure_logging(level='debug')
        tb.trace()

# pylint: disable = no-value-for-parameter
main()

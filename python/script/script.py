import sys
import click, click_help_colors
from loguru import logger
from rich   import traceback

traceback.install(width=80, extra_lines=1)

logfmt = '<level>[{level} {time:YYYY-MM-DD HH:mm:ss}]</> {message}\n'

def configure_logging(fmt=logfmt, level='INFO'):
    logger.configure(handlers=[dict(sink=sys.stderr, format=fmt, level=level)])

configure_logging()

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

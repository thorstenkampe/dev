import sys
import click, click_help_colors
from loguru import logger
from rich import traceback

traceback.install(width=80, extra_lines=1)

# https://github.com/Delgan/loguru/issues/428
def formatter(record):
    level_labels = {'SUCCESS': 'SUCC', 'WARNING': 'WARN', 'CRITICAL': 'CRIT'}
    level_name   = record['level'].name
    level        = level_labels.get(level_name, level_name)
    return f'<level>[{level} {{time:YYYY-MM-DD HH:mm:ss}}]</> {{message}}\n'

def configure_logging(fmt=formatter, level='INFO'):
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

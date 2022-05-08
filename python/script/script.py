import click, click_help_colors, rich.traceback
# pylint: disable = unused-import
from loguru import logger
import toolbox as tb

rich.traceback.install(width=80, extra_lines=1)
tb.logging()

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
        tb.logging(level='debug')
        tb.trace()

# pylint: disable = no-value-for-parameter
main()

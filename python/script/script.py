# https://click.palletsprojects.com/en/7.x/#documentation, https://github.com/click-contrib/click-help-colors
import click, click_help_colors

@click.command(
    context_settings   = {'help_option_names': ['-h', '--help']},
    cls                = click_help_colors.HelpColorsCommand,
    help_headers_color = 'cyan',
    help_options_color = 'bright_white'
)

# MAIN CODE STARTS HERE #

def main():
    '''purpose of script'''

main()

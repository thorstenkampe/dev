from click             import command            # https://click.palletsprojects.com/en/7.x/#documentation
from click_help_colors import HelpColorsCommand  # https://github.com/click-contrib/click-help-colors

@command(
    context_settings   = {'help_option_names': ['-h', '--help']},
    cls                = HelpColorsCommand,
    help_headers_color = 'cyan',
    help_options_color = 'bright_white'
)

# MAIN CODE STARTS HERE #

def main():
    '''purpose of script'''

main()

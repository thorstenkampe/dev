import importlib.metadata, pathlib, re, socket, sys, urllib
import outdated, pycompat, qprompt, tqdm
if pycompat.system.is_windows:
    import pythoncom, pywintypes, win32com.client
    pythoncom.CoInitialize()  # "com_error: CoInitialize has not been called."
from collections.abc import MappingView
from pandas          import DataFrame, Series
from rich            import console

defaults = {
    'port':    {
        'mssql':      1433,
        'mysql':      3306,
        'oracle':     1521,
        'postgresql': 5432
    },

    'db_user': {
        'mssql':      'sa',
        'mysql':      'root',
        'oracle':     'sys',
        'postgresql': 'postgres'
    }
}

def stringify(obj):
    if type(obj) == float:
        return f'{obj:.1f}'
    else:
        return str(obj)

#
def file_version(file):
    if pycompat.system.is_windows:
        # * http://timgolden.me.uk/python/win32_how_do_i/get_dll_version.html
        # * https://github.com/mhammond/pywin32/blob/d64fac8d7bda2cb1d81e2c9366daf99e802e327f/win32/Demos/getfilever.py
        # * https://stackoverflow.com/questions/580924/how-to-access-a-files-properties-on-windows
        try:
            return win32com.client.Dispatch('Scripting.FileSystemObject').GetFileVersion(file)
        except pywintypes.com_error:
            pass
    else:
        try:
            return '.'.join(re.findall(r'\d+\.\d+', pathlib.Path(file).name))
        except IndexError:
            pass

def pkg_version(pkg):
    '''return the installed version of package or None if not installed'''
    try:
        return importlib.metadata.version(pkg)
    except importlib.metadata.PackageNotFoundError:
        return None

def latest_version(pkg):
    return outdated.check_outdated(pkg, '')[1]

def ident(x):
    return x

def is_localdb(dsn):
    localdb    = r'(localdb)\mssqllocaldb'
    parsed_url = urllib.parse.urlsplit(dsn)

    if parsed_url.scheme == 'mssql':
        return parsed_url.hostname == localdb

    elif not parsed_url.scheme:
        return parsed_url.path.lower() == localdb

    else:
        return False

# https://pyinstaller.readthedocs.io/en/stable/runtime-information.html
def is_pyinstaller():
    return getattr(sys, 'frozen', False)

def remove_ansi(text):
    return re.sub(r'\x1b\[[\d;]+m', '', text)

def dmap(dict_, keyfunc):
    '''apply function to value of dictionary'''
    return {key: keyfunc(dict_[key]) for key in dict_}

def cast_config(config):  # NOSONAR
    '''cast ini values to integer, float, boolean, or None if possible'''
    def cast(value):
        try:
            value = int(value)
        except ValueError:
            try:
                value = float(value)
            except ValueError:
                if value in ['True', 'False', 'None']:
                    # pylint: disable = eval-used
                    value = eval(value)

        return value

    myconfig = {}

    for section in config.sections():
        myconfig[section] = dmap(config[section], cast)

    return myconfig

def typeof(obj):
    '''equivalent of `type` for `isinstance`'''
    for type_ in (dict, list, set, tuple, MappingView, Series, DataFrame):
        if isinstance(obj, type_):
            return type_

    return None

def host_reachable(url):
    # * doesn't work through SSH tunnel
    # * https://docs.python.org/3/howto/sockets.html
    urlp = urllib.parse.urlsplit(url)

    if not urlp.scheme:
        raise ValueError('no URL scheme given')

    if is_localdb(url):
        return True

    if urlp.port:
        port = urlp.port
    else:  # no port from parsed URL
        try:
            port = defaults['port'][urlp.scheme.split('+')[0]]
        except KeyError:
            msg = f'no port given and can\'t find default port for scheme "{urlp.scheme}"'
            raise ValueError(msg) from None

    try:
        sock = socket.create_connection((urlp.hostname, port), timeout=0.048)
    except (ConnectionRefusedError, socket.gaierror, socket.timeout):
        return False
    else:
        sock.close()
        return True

# input/output #  NOSONAR
def progress(iter_, func):
    '''
    >>> import time
    >>> def func(x): time.sleep(0.1)
    >>> progress(range(50), func)
    '''

    fmt  = '[{bar}]{percentage:3.0f}% ({n_fmt}/{total_fmt})  time left: {remaining}'
    pbar = tqdm.tqdm(iterable=iter_, ncols=80, bar_format=fmt, leave=False)

    for item in pbar:
        func(item)

    pbar.close()

def select(selections, title):
    '''
    >>> selections = ['MSSQL', 'MySQL', 'Oracle', 'PostgreSQL', 'SQLite']
    >>> select(selections, 'Select database [1-5]')
    '''

    menu = qprompt.enum_menu(strs=selections, header=title, msg='')
    return int(menu.show()) - 1

def spinner(func):
    '''
    >>> import time
    >>> def func(): time.sleep(10)
    >>> spinner(func)
    '''

    con = console.Console()
    with con.status(status='', spinner='bouncingBall', spinner_style='royal_blue1',
                    speed=0.4):
        func()

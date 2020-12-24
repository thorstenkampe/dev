import importlib.metadata, pathlib, re, socket, urllib
import outdated, pycompat
import tb_sql
if pycompat.system.is_windows:
    import pythoncom, pywintypes, win32com.client
    pythoncom.CoInitialize()  # "com_error: CoInitialize has not been called."
from collections.abc import MappingView
from pandas          import DataFrame, Series

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

def dmap(dict_, keyfunc):
    '''apply function to values of dictionary'''
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
    default_port = {'mssql': 1433, 'mysql': 3306, 'oracle': 1521, 'postgresql': 5432}
    urlp = urllib.parse.urlsplit(url)

    if not urlp.scheme:
        raise ValueError('no URL scheme given')

    if tb_sql.islocaldb(url):
        return True

    if urlp.port:
        port = urlp.port
    else:  # no port from parsed URL
        try:
            port = default_port[urlp.scheme.split('+')[0]]
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

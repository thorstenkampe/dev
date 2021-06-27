import importlib.metadata, pathlib, re, socket, sys, urllib
import outdated, pycompat, pyodbc, qprompt, sqlalchemy as sa, tqdm
if pycompat.system.is_windows:
    import pythoncom, pywintypes, win32com.client
    pythoncom.CoInitialize()  # "com_error: CoInitialize has not been called."
from collections     import defaultdict, OrderedDict
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

    if   parsed_url.scheme == 'mssql':
        return parsed_url.hostname == localdb

    elif not parsed_url.scheme:
        return localdb in parsed_url.path.lower()

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

# DATA #
def shape(seq):
    dimension = tuple()
    # MappingView is any of dict.items(), keys(), values()
    while typeof(seq) in (MappingView, list, tuple):
        dimension += (len(seq), )
        try:
            seq = list(seq)[0]
        except IndexError:  # sequence is empty
            break
    return dimension

def sort_index(dict_, keyfunc=ident):
    '''sort dictionary by index (dictionary key)'''
    return OrderedDict(sorted(dict_.items(), key=lambda kv: keyfunc(kv[0])))

def sort_value(dict_, keyfunc=ident):
    '''sort dictionary by value'''
    return OrderedDict(sorted(dict_.items(), key=lambda kv: keyfunc(kv[1])))

def groupby(iter_, keyfunc=ident, axis=None):
    '''group iterable into equivalence classes - see http://en.wikipedia.org/wiki/Equivalence_relation'''
    type_    = typeof(iter_)
    eq_class = defaultdict(type_)

    if axis and type_ != DataFrame:
        raise TypeError('axis specified but iterable is not dataframe')

    if axis not in [None, 'rows', 'columns']:
        raise ValueError("axis must be 'rows' or 'columns'")

    if   type_ == dict:
        iter_ = iter_.items()

        def grouper(proj, elem):
            eq_class[proj][elem[0]] = elem[1]

    elif type_ == list:
        def grouper(proj, elem):
            eq_class[proj].append(elem)

    elif type_ == set:
        def grouper(proj, elem):
            eq_class[proj].add(elem)

    elif type_ == tuple:
        def grouper(proj, elem):
            eq_class[proj] += (elem,)

    elif type_ == Series:
        return iter_.groupby(iter_.apply(keyfunc), axis='index', sort=False)

    # https://realpython.com/pandas-groupby/
    elif type_ == DataFrame:
        if axis == 'columns':
            iter_ = iter_.transpose()  # = apply by axis=rows, groupby by axis=columns
        return iter_.groupby(iter_.apply(keyfunc, axis='columns'), axis='index', sort=False)

    else:
        msg = ('Type not supported for iterable. Use dictionary, list, set, tuple,'
               ' series, or dataframe.')
        raise TypeError(msg)

    for proj, elem in zip(map(keyfunc, iter_), iter_):
        grouper(proj, elem)

    return dict(eq_class)

# SQL #
def databases(engine):
    query = {
        'mssql':      'select name from sys.databases',
        'mysql':      'show databases',
        'oracle':     'select pdb_name from dba_pdbs',
        'postgresql': 'select datname from pg_database'
    }

    with engine.connect() as conn:
        result = conn.execute(sa.text(query[engine.name]))
        return [db[0] for db in result]

def tables(engine, schema=None):
    return sa.inspect(engine).get_table_names(schema)

def engine(dsn):
    '''create SQLAlchemy engine with sane parameters'''

    # dsn = scheme://netloc/path
    urlp = urllib.parse.urlsplit(dsn)
    scheme, netloc, path, _, _ = urlp

    query_params = {
        # https://docs.microsoft.com/en-us/sql/relational-databases/native-client/applications/using-connection-string-keywords-with-sql-server-native-client#odbc-driver-connection-string-keywords
        'mssql': {'driver': 'ODBC+Driver+17+for+SQL+Server', 'Encrypt': 'yes', 'TrustServerCertificate': 'yes'},

        # https://docs.sqlalchemy.org/en/13/dialects/oracle.html#ensuring-the-correct-client-encoding
        'oracle': {'service_name': path[1:], 'encoding': 'UTF-8', 'nencoding': 'UTF-8'},
    }

    engine_params = {
        # only necessary for interactive use (e.g. IPython) to prevent open sessions
        'default': {'poolclass': sa.pool.NullPool, 'future': True},

        # https://docs.sqlalchemy.org/en/13/dialects/oracle.html#max-identifier-lengths
        'oracle': {'exclude_tablespaces': None, 'max_identifier_length': 30}
    }

    query_params     = query_params.get(scheme, {})
    my_engine_params = engine_params['default']
    my_engine_params.update(engine_params.get(scheme, {}))

    if   scheme == 'mssql':
        # https://github.com/sqlalchemy/sqlalchemy/issues/5440
        pyodbc.pooling = False

        if is_localdb(dsn):
            query_params['Encrypt'] = 'no'

    elif scheme == 'mysql':
        # change default driver for MySQL from `mysqlclient` to MySQL Connector/Python
        # https://dev.mysql.com/doc/connector-python/en/connector-python-connectargs.html
        dsn = dsn.replace('mysql://', 'mysql+mysqlconnector://')

    elif scheme == 'oracle':
        # remove database (path) because we'll pass it as `service_name` query parameter
        dsn = f'oracle://{netloc}/'

        if urlp.username == 'sys':
            query_params['mode'] = 'sysdba'

    dsn += '?' + '&'.join(f'{key}={value}' for key, value in query_params.items())

    return sa.create_engine(dsn, **my_engine_params)

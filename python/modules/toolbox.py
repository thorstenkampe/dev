def pkg_version(pkg):
    '''return the installed version of package or None if not installed'''
    import importlib.metadata
    try:
        return importlib.metadata.version(pkg)
    except importlib.metadata.PackageNotFoundError:
        return None

def ident(x):
    return x

def is_localdb(dsn):
    import urllib
    localdb    = r'(localdb)\mssqllocaldb'
    parsed_url = urllib.parse.urlsplit(dsn)

    if   parsed_url.scheme == 'mssql':
        return parsed_url.hostname == localdb

    elif not parsed_url.scheme:
        return localdb in parsed_url.path.lower()

    else:
        return False

def is_pyinstaller():
    # https://pyinstaller.readthedocs.io/en/stable/runtime-information.html
    import sys
    return getattr(sys, 'frozen', False)

def dmap(dict_, keyfunc):
    '''apply function to value of dictionary'''
    return {key: keyfunc(dict_[key]) for key in dict_}

def cast(value):
    '''cast value to integer, float, boolean, or None if possible'''
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

def port_reachable(url):
    # * doesn't work through SSH tunnel
    # * https://docs.python.org/3/howto/sockets.html
    import socket, urllib
    default_port = {'mssql': 1433, 'mysql': 3306, 'oracle': 1521, 'postgresql': 5432}
    urlp         = urllib.parse.urlsplit(url)

    if not urlp.scheme:
        raise ValueError('no URL scheme given')

    if is_localdb(url):
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
    except (OSError, socket.gaierror, socket.timeout):
        return False
    else:
        sock.close()
        return True

# input/output #  NOSONAR
def prettytab(iter_, headers=None, pager=False, **kwargs):
    import pandas as pd, rich.box, rich.console, rich.table

    def stringify(obj):
        if type(obj) == float:
            return f'{obj:.1f}'
        else:
            return str(obj)

    if not headers:
        headers = []

    if type(iter_) == pd.DataFrame:
        if iter_.index.name:
            index_name = iter_.index.name
        else:
            index_name = ''

        headers = [index_name] + list(iter_.columns)
        iter_   = iter_.itertuples()

    iter_ = list(iter_)

    if pager:
        tabbox = rich.box.ASCII
    else:
        tabbox = rich.box.MINIMAL_HEAVY_HEAD

    tab = rich.table.Table(*headers, safe_box=False, box=tabbox, show_edge=False,
                           show_header=bool(headers), **kwargs)

    for row in iter_:
        row = [stringify(item) for item in row]
        tab.add_row(*row)

    con = rich.console.Console()
    if pager:
        with con.pager(styles=True):
            con.print(tab)
    else:
        con.print(tab)

def progress(func, iter_=None):
    '''
    >>> import time
    >>> def func(x): time.sleep(0.1)
    >>> progress(func, iter_=range(50))
    >>>
    >>> def func(): time.sleep(5)
    >>> progress(func)
    '''
    import alive_progress

    if iter_:
        for item in alive_progress.alive_it(iter_, bar='circles', spinner=None):
            func(item)
    else:
        with alive_progress.alive_bar(bar=False, stats=False, elapsed=False, monitor=False,
                                      stats_end=False):
            func()

def trace():
    import subprocess, sys
    if not (sys.gettrace() or is_pyinstaller()):
        # pylint: disable = subprocess-run-check
        subprocess.run([sys.executable, '-m', 'trace', '--trace', '--ignore-dir',
                       sys.prefix] + sys.argv)

# DATA #
def sort_index(dict_, keyfunc=ident):
    '''sort dictionary by index (dictionary key)'''
    import collections
    return collections.OrderedDict(sorted(dict_.items(), key=lambda kv: keyfunc(kv[0])))

def sort_value(dict_, keyfunc=ident):
    '''sort dictionary by value'''
    import collections
    return collections.OrderedDict(sorted(dict_.items(), key=lambda kv: keyfunc(kv[1])))

def groupby(iter_, keyfunc=ident, axis=None):
    '''group iterable into equivalence classes - see http://en.wikipedia.org/wiki/Equivalence_relation'''
    import collections
    import pandas as pd

    type_    = type(iter_)
    eq_class = collections.defaultdict(type_)

    if axis and type_ != pd.DataFrame:
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

    elif type_ == pd.Series:
        return iter_.groupby(iter_.apply(keyfunc), axis='index', sort=False)

    # https://realpython.com/pandas-groupby/
    elif type_ == pd.DataFrame:
        if axis == 'columns':
            iter_ = iter_.transpose()  # = apply by axis=rows, groupby by axis=columns
        return iter_.groupby(iter_.apply(keyfunc, axis='columns'), axis='index',
                             sort=False)

    else:
        raise TypeError('Type not supported for iterable. Use dictionary, list, '
                        'set, tuple, series, or dataframe.')

    for proj, elem in zip(map(keyfunc, iter_), iter_):
        grouper(proj, elem)

    return dict(eq_class)

# SQLALCHEMY #
def engine(dsn):
    '''create SQLAlchemy engine with sane parameters'''
    import urllib
    import pyodbc, sqlalchemy as sa

    # dsn = scheme://netloc/path
    urlp = urllib.parse.urlsplit(dsn)
    scheme, netloc, path, _, _ = urlp

    # only necessary for interactive use (e.g. IPython) to prevent open sessions
    engine_params = {'poolclass': sa.pool.NullPool, 'future': False}
    query_params  = {}

    if   scheme == 'mssql':
        # https://docs.microsoft.com/en-us/sql/relational-databases/native-client/applications/using-connection-string-keywords-with-sql-server-native-client#odbc-driver-connection-string-keywords
        query_params = {'driver': 'ODBC+Driver+17+for+SQL+Server', 'Encrypt': 'yes',
                        'TrustServerCertificate': 'yes'}

        if is_localdb(dsn):
            query_params['Encrypt'] = 'no'

        # https://github.com/sqlalchemy/sqlalchemy/issues/5440
        pyodbc.pooling = False

    elif scheme == 'mysql':
        # change default driver for MySQL from `mysqlclient` to MySQL Connector/Python
        # https://dev.mysql.com/doc/connector-python/en/connector-python-connectargs.html
        dsn = dsn.replace('mysql://', 'mysql+mysqlconnector://')

    elif scheme == 'oracle':
        # https://docs.sqlalchemy.org/en/14/dialects/oracle.html#max-identifier-lengths
        engine_params.update({'exclude_tablespaces': None, 'max_identifier_length': 30})

        # https://docs.sqlalchemy.org/en/14/dialects/oracle.html#ensuring-the-correct-client-encoding
        query_params = {'service_name': path[1:], 'encoding': 'UTF-8', 'nencoding': 'UTF-8'}

        if urlp.username == 'sys':
            query_params['mode'] = 'sysdba'

        # remove database (path) because we'll pass it as `service_name` query parameter
        dsn = f'oracle://{netloc}/'

    dsn += '?' + '&'.join(f'{key}={value}' for key, value in query_params.items())

    return sa.create_engine(dsn, **engine_params)

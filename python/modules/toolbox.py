# no unit test yet
def filever(file):
    import pycompat, re
    if pycompat.system.is_windows:
        # `filever(r'C:\Windows\System32\msodbcsql18.dll')` -> '2018.181.2.1'
        import win32com.client
        # * http://timgolden.me.uk/python/win32_how_do_i/get_dll_version.html
        # * https://github.com/mhammond/pywin32/blob/d64fac8d7bda2cb1d81e2c9366daf99e802e327f/win32/Demos/getfilever.py
        # * https://stackoverflow.com/questions/580924/how-to-access-a-files-properties-on-windows
        return win32com.client.Dispatch('Scripting.FileSystemObject').GetFileVersion(file)
    else:
        # `filever('libmsodbcsql-18.0.so.1.1'` -> '18.0.1.1'
        return '.'.join(re.findall(r'\d+\.\d+', file))

def pkg_version(pkg, type_):
    '''
    return the installed or latest available version of package (or None if not
    installed
    '''
    import importlib.metadata
    import outdated

    if type_ == 'current':
        try:
            return importlib.metadata.version(pkg)
        except importlib.metadata.PackageNotFoundError:
            return None
    elif type_ == 'latest':
        return outdated.check_outdated(pkg, '0')[1]

def ident(x):
    return x

def is_ipython_terminal():
    try:
        # we treat QT Console and Notebook as one
        return get_ipython().__class__.__name__ == 'TerminalInteractiveShell'
    except NameError:
        return False

def is_localdb(dsn):
    import urllib
    localdb = r'(localdb)\mssqllocaldb'
    urlp    = urllib.parse.urlsplit(dsn)

    if   urlp.scheme == 'mssql':
        return urlp.hostname == localdb

    elif not urlp.scheme:
        return localdb in urlp.path.lower()

    else:
        return False

def is_pyinstaller():
    # https://pyinstaller.readthedocs.io/en/stable/runtime-information.html
    import sys
    return hasattr(sys, 'frozen') and hasattr(sys, '_MEIPASS')

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

def http_status_code(url):
    # https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml
    import http.client, urllib

    urlp       = urllib.parse.urlsplit(url)
    connection = http.client.HTTPSConnection(urlp.hostname, port = urlp.port)
    connection.request('HEAD', urlp.path)

    # -> http.HTTPStatus(status).phrase, http.HTTPStatus(status).description
    return connection.getresponse().status

def port_reachable(host, port):
    # * doesn't work through SSH tunnel
    # * https://docs.python.org/3/howto/sockets.html
    import socket

    try:
        sock = socket.create_connection((host, port), timeout=0.048)
    except (OSError, socket.gaierror, socket.timeout):
        return False
    else:
        sock.close()
        return True

def transpose(table):
    return list(zip(*table))

# input/output #  NOSONAR
def logging(logfmt='', level='info'):
    import os, sys
    from loguru import logger

    if not logfmt:
        if os.isatty(2):
            timestamp = ''
        else:
            timestamp = ' {time:YYYY-MM-DD HH:mm:ss}'
        logfmt = f'<level>[{{level}}{timestamp}]</> {{message}}\n'

    logger.configure(handlers=[dict(sink=sys.stderr, level=level.upper(), format=logfmt)])

def prettytab(iter_, headers=None, **kwargs):
    import pandas, rich.box, rich.console, rich.table

    if not headers:
        headers = []

    if type(iter_) == pandas.DataFrame:
        if iter_.index.name:
            index_name = iter_.index.name
        else:
            index_name = ''

        headers = [index_name] + list(iter_.columns)
        iter_   = iter_.itertuples()

    headers = [str(header) for header in headers]

    tab = rich.table.Table(*headers, safe_box=False, box=rich.box.MINIMAL_HEAVY_HEAD,
                           show_edge=False, show_header=bool(headers), **kwargs)

    for row in iter_:
        row = [str(item) for item in row]
        tab.add_row(*row)

    con = rich.console.Console()
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
def groups_lst(groupby):
    '''
    return `groups`-like dictionary from Pandas GroupBy object with list as values
    instead of index
    '''
    return dmap(groupby.groups, lambda x: x.to_list())

def groupby(iter_, keyfunc=ident, axis=None):
    '''group iterable into equivalence classes - see http://en.wikipedia.org/wiki/Equivalence_relation'''
    import collections
    import pandas

    type_    = type(iter_)
    eq_class = collections.defaultdict(type_)

    if   axis and type_ != pandas.DataFrame:
        raise TypeError('axis specified but iterable is not dataframe')

    elif axis not in [None, 'rows', 'columns']:
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

    elif type_ == pandas.Series:
        return iter_.groupby(iter_.apply(keyfunc), axis='index', sort=False)

    # https://realpython.com/pandas-groupby/
    elif type_ == pandas.DataFrame:
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
    import sqlalchemy as sa

    # dsn = scheme://netloc/path
    urlp = urllib.parse.urlsplit(dsn)
    scheme, netloc, path, _, _ = urlp

    connect_params = {}
    engine_params  = {}
    query_params   = {}

    if   scheme == 'mssql':
        # https://docs.microsoft.com/en-us/sql/relational-databases/native-client/applications/using-connection-string-keywords-with-sql-server-native-client#odbc-driver-connection-string-keywords
        query_params = {'driver': 'ODBC+Driver+18+for+SQL+Server', 'Encrypt': 'yes',
                        'timeout': 5, 'TrustServerCertificate': 'yes'}

        if is_localdb(dsn):
            query_params['Encrypt'] = 'no'

    elif scheme == 'mysql':
        # change default driver for MySQL from `mysqlclient` to MySQL Connector/Python
        # https://dev.mysql.com/doc/connector-python/en/connector-python-connectargs.html
        dsn = dsn.replace('mysql://', 'mysql+mysqlconnector://')
        connect_params['connect_timeout'] = 5

    elif scheme == 'oracle':
        # https://docs.sqlalchemy.org/en/20/dialects/oracle.html#max-identifier-lengths
        engine_params.update({'exclude_tablespaces': None, 'max_identifier_length': 30})

        # https://docs.sqlalchemy.org/en/20/dialects/oracle.html#ensuring-the-correct-client-encoding
        query_params = {'service_name': path[1:], 'encoding': 'UTF-8', 'nencoding': 'UTF-8'}

        if urlp.username == 'sys':
            query_params['mode'] = 'sysdba'

        # remove database (path) because we'll pass it as `service_name` query parameter
        dsn = f'oracle+oracledb://{netloc}/'

    elif scheme == 'postgresql':
        # change default driver for PostgreSQL from `psycopg2` to `psycopg`
        dsn = dsn.replace('postgresql://', 'postgresql+psycopg://')
        connect_params['connect_timeout'] = 5

    dsn += '?' + '&'.join(f'{key}={value}' for key, value in query_params.items())

    return sa.create_engine(dsn, connect_args=connect_params, **engine_params)

# no unit test yet
def sqlquery(engine, query):
    import sqlalchemy as sa
    with engine.connect() as conn:
        return conn.execute(sa.text(query)).all()

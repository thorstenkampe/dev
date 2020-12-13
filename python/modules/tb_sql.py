import urllib
import pyodbc, sqlalchemy as sa

def islocaldb(dsn):
    return urllib.parse.urlsplit(dsn).hostname == r'(localdb)\mssqllocaldb'

def databases(engine):
    query = {
        'mssql':      'select name from sys.databases',
        'mysql':      'show databases',
        'oracle':     'select pdb_name from dba_pdbs',
        'postgresql': 'select datname from pg_database'
    }

    result = engine.execute(query[engine.name])
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
        'default': {'poolclass': sa.pool.NullPool},

        # https://docs.sqlalchemy.org/en/13/dialects/oracle.html#max-identifier-lengths
        'oracle': {'exclude_tablespaces': None, 'max_identifier_length': 30}
    }

    query_params     = query_params.get(scheme, {})
    my_engine_params = engine_params['default']
    my_engine_params.update(engine_params.get(scheme, {}))

    if   scheme == 'mssql':
        # https://github.com/sqlalchemy/sqlalchemy/issues/5440
        pyodbc.pooling = False

        if islocaldb(dsn):
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

    dsn += '?' + ';'.join(f'{key}={value}' for key, value in query_params.items())

    return sa.create_engine(dsn, **my_engine_params)

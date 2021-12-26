# pylint: disable = redefined-builtin
import types
import toolbox as tb
from configparser import ConfigParser

# pytest helpers
def even(integer):
    return not integer % 2

#
list    = [1, 2, 3, 4, 5, 6, '7', '8 8', '']

set     = {1, 2, 3, 4, 5, 6, '7', '8 8', ''}

tuple   = (1, 2, 3, 4, 5, 6, '7', '8 8', '')

dict    = {'a': 1, 'b': 2, 'c': 3, 'd': 4, 'e': 5, 'f': 6, 'g': '7', 'h h': '8 8', 9: ''}

str     = 'The quick brown fox jumps over the lazy dog'

table   = [
    ('1a', '1b', '1c', 1.0, 1),
    ('2a', '2b', '2c', 2.0, 2),
    ('3a', '3b', '3c', 3.0, 3),
    ('4a', '4b', '4c', 4.0, 4)
]

redis   = {'list': ['0a', '1a'], 'hash': {'2': '2b', '3': '3b'}, 'string': 'abc'}

config  = ConfigParser()
config['DEFAULT'] = {'def_key': 'def_value'}
config['section'] = {'int': '1', 'float': '1.0', 'true': 'True', 'false': 'False', 'none': 'None', 'str': 'text'}
section = config['section']

# Pandas
try:
    from pandas import DataFrame, Series

    sr    = Series(
        data  = list,
        # non-numeric indexing enables label _and_ position based indexing (sr['a'], sr[0])
        index = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'],
    )
    sr.name       = 'sr'
    sr.index.name = 'index'

    df    = DataFrame(
        data    = table,
        index   = [1, 2, 3, 4],
        columns = ['a', 'b', 'c', 'd', 'e']
    )
    df.index.name   = 'index'
    df.columns.name = 'cols'

    group = tb.groupby(df, keyfunc=lambda x: even(x['e']))
except ModuleNotFoundError:
    pass

try:
    from toolbox import engine
    dsn = types.SimpleNamespace(
        mslocal     = engine(r'mssql://(LocalDB)\MSSQLLocalDB/Chinook'),
        mslinux     = engine('mssql://sa:password@db/Chinook'),
        mswindows   = engine('mssql://sa:password@windows-db/Chinook'),

        mylocal     = engine('mysql://root:password@rednails/Chinook'),
        mylinux     = engine('mysql://root:password@db/Chinook'),
        mywindows   = engine('mysql://root:password@windows-db/Chinook'),

        oralinux    = engine('oracle://sys:password@db/xe'),
        orawindows  = engine('oracle://sys:password@windows-db/xepdb1'),
        oracdb      = engine('oracle://sys:password@windows-db'),

        postlocal   = engine('postgresql://postgres:password@rednails/'),
        postlinux   = engine('postgresql://postgres:password@db/'),
        postwindows = engine('postgresql://postgres:password@windows-db/'),

        litelocal   = engine(r'sqlite:///F:\cygwin\home\thorsten\data\Chinook.sqlite'),
        litelinux   = engine('sqlite:////home/thorsten/data/Chinook.sqlite')
    )
except ModuleNotFoundError:
    pass

# pylint: disable = redefined-builtin
import configparser, types
import toolbox as tb

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

config  = configparser.ConfigParser()
_config = {
    'DEFAULT': {'def_key': 'def_value'},
    'section': {'int': '1', 'float': '1.0', 'true': 'True', 'false': 'False', 'none': 'None', 'str': 'text'}
}
config.read_dict(_config)
section = config['section']

# Pandas
try:
    import pandas

    sr    = pandas.Series(
        data  = list,
        # non-numeric indexing enables label _and_ position based indexing (sr['a'], sr[0])
        index = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'],
    )
    sr.name       = 'sr'
    sr.index.name = 'index'

    df    = pandas.DataFrame(
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
    dsn = types.SimpleNamespace(
        mslocal   = tb.engine(r'mssql://(LocalDB)\MSSQLLocalDB/Chinook'),

        mylocal   = tb.engine('mysql://root:password@rednails/Chinook'),

        postlocal = tb.engine('postgresql://postgres:password@rednails/chinook'),

        litelocal = tb.engine(r'sqlite:///F:\cygwin\home\thorsten\data\Chinook.sqlite'),
        litelinux = tb.engine('sqlite:////home/thorsten/data/Chinook.sqlite')
    )
except ModuleNotFoundError:
    pass

# pytest
# pylint: disable = too-few-public-methods
import re
import pip, pycompat
from collections import OrderedDict
from socket      import create_server
from pytest      import raises
from test        import (
    config, even, df, dict as dict_, even, groups_lst, list as list_, set as set_,
    sr, str as str_, table, tuple as tuple_
)
from toolbox     import *  # NOSONAR

def test_file_version():
    winfile   = r'\scoop\apps\miniconda3\current\envs\main\python.exe'
    if pycompat.system.is_windows:
        match = r'3\.\d{1,2}\.\d{3,4}\.\d{4}'  # 3.9.150.1013
        assert re.fullmatch(match, file_version(winfile))
    else:
        assert file_version('/libpython3.8.so.1.0') == '3.8.1.0'

class Test_pkg_version:  # NOSONAR
    def test_installed(self):
        assert pkg_version('pip') == pip.__version__

    def test_not_installed(self):
        assert pkg_version('DoesNotExist') is None

def test_latest_version():
    assert latest_version('pip-install-test') == '0.5'

class Test_is_localdb:  # NOSONAR
    def test_mslocal(self):
        assert is_localdb(r'mssql://(LocalDB)\MSSQLLocalDB')  # NOSONAR

    def test_mslocal_no_scheme(self):
        assert is_localdb(r'(LocalDB)\MSSQLLocalDB')

    def test_mysql(self):
        assert not is_localdb(r'mysql://(LocalDB)\MSSQLLocalDB')

def test_dmap():
    result = {'a': False, 'b': True, 'c': False, 'd': True, 'e': False, 'f': True, 'g': False, 'h': True, 9: False}
    assert dmap(dict_, keyfunc=even) == result

def test_cast_config():
    result = {'section': {'int': 1, 'float': 1.0, 'true': True, 'false': False, 'none': None, 'str': 'text'}}
    assert cast_config(config) == result

def test_typeof():
    assert typeof(set_) == set

class Test_host_reachable:  # NOSONAR
    def test_reachable(self):
        server = create_server(('localhost', 0))
        port   = server.getsockname()[1]
        assert host_reachable(f'scheme://localhost:{port}')
        server.close()

    def test_mslocal(self):
        assert host_reachable(r'mssql://(LocalDB)\MSSQLLocalDB')  # NOSONAR

    def test_default_port(self):
        server = create_server(('localhost', 1521))
        assert host_reachable('oracle://localhost')
        server.close()

    def test_unreachable(self):
        assert not host_reachable('scheme://localhost:1')

    def test_no_port_unknown_scheme(self):
        match = '^no port given and can\'t find default port for scheme "scheme"$'
        with raises(ValueError, match=match):
            host_reachable('scheme://')

    def test_no_scheme(self):
        with raises(ValueError, match='^no URL scheme given$'):
            host_reachable('liteloc')

# DATA #
class Test_groupby:  # NOSONAR
    def test_dict(self):
        group  = groupby(dict_, keyfunc=lambda x: even(x[1]))
        result = {False: {'a': 1, 'c': 3, 'e': 5, 'g': 7, 9: 9}, True: {'b': 2, 'd': 4, 'f': 6, 'h': 8}}
        assert group == result

    def test_list(self):
        group = groupby(list_, keyfunc=even)
        assert group == {False: [1, 3, 5, 7, 9], True: [2, 4, 6, 8]}

    def test_set(self):
        group = groupby(set_, keyfunc=even)
        assert group == {False: {3, 9, 1, 7, 5}, True: {8, 6, 4, 2}}

    def test_tuple(self):
        group = groupby(tuple_, keyfunc=even)
        assert group == {False: (1, 3, 5, 7, 9), True: (2, 4, 6, 8)}

    def test_error_label(self):
        with raises(TypeError, match='^axis specified but iterable is not dataframe$'):
            groupby(sr, axis='rows')

    def test_error_axis(self):
        with raises(ValueError, match="^axis must be 'rows' or 'columns'$"):
            groupby(df, axis='row')

    def test_series(self):
        group  = groupby(sr, keyfunc=even)
        result = {False: ['a', 'c', 'e', 'g', 'i'], True: ['b', 'd', 'f', 'h']}
        assert groups_lst(group) == result

    def test_dataframe_group_by_row(self):
        group = groupby(df, keyfunc=lambda x: even(x['e']), axis='rows')
        assert groups_lst(group) == {False: [1, 3], True: [2, 4]}

    def test_dataframe_group_by_column(self):
        group = groupby(df, keyfunc=lambda x: type(x[1]), axis='columns')
        assert groups_lst(group) == {float: ['d'], int: ['e'], str: ['a', 'b', 'c']}

    def test_error_type(self):
        match = r'^Type not supported for iterable\. Use dictionary, list, set, tuple, series, or dataframe\.$'
        with raises(TypeError, match=match):
            groupby(str_)

def test_shape():
    assert shape(table) == (4, 5)

def test_sort_index():
    result = OrderedDict([(9, 9), ('a', 1), ('b', 2), ('c', 3), ('d', 4), ('e', 5), ('f', 6), ('g', 7), ('h', 8)])
    assert sort_index(dict_, keyfunc=str) == result

def test_sort_value():
    result = OrderedDict([('a', 1), ('c', 3), ('e', 5), ('g', 7), (9, 9), ('b', 2), ('d', 4), ('f', 6), ('h', 8)])
    assert sort_value(dict_, keyfunc=even) == result

# SQLALCHEMY #
class Test_engine:  # NOSONAR
    def test_mslocal(self):
        result = r'Engine(mssql://(LocalDB)\MSSQLLocalDB?Encrypt=no&TrustServerCertificate=yes&driver=ODBC+Driver+17+for+SQL+Server)'
        assert str(engine(r'mssql://(LocalDB)\MSSQLLocalDB')) == result

    def test_mslinux(self):
        result = 'Engine(mssql://?Encrypt=yes&TrustServerCertificate=yes&driver=ODBC+Driver+17+for+SQL+Server)'
        assert str(engine('mssql://')) == result

    def test_mylocal(self):
        assert str(engine('mysql://')) == 'Engine(mysql+mysqlconnector://)'

    def test_oracle(self):
        assert str(engine('oracle://')) == 'Engine(oracle:///?encoding=UTF-8&nencoding=UTF-8)'

    def test_oracle_sys(self):
        result = 'Engine(oracle://sys@/?encoding=UTF-8&mode=sysdba&nencoding=UTF-8)'
        assert str(engine('oracle://sys@')) == result

    def test_postgresql(self):
        assert str(engine('postgresql://')) == 'Engine(postgresql://)'

    def test_sqlite(self):
        assert str(engine('sqlite:///')) == 'Engine(sqlite:///)'

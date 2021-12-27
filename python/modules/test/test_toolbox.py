# pytest
# pylint: disable = too-few-public-methods
import collections, pip, socket
import pytest
import test, toolbox as tb

typeint = type(0)
typestr = type('str')

def groups_lst(groupby):
    '''
    return `groups`-like dictionary from Pandas GroupBy object with list as values
    instead of index for pytest assertions
    '''
    return tb.dmap(groupby.groups, lambda x: x.to_list())

class Test_pkg_version:  # NOSONAR
    def test_installed(self):
        assert tb.pkg_version('pip') == pip.__version__

    def test_not_installed(self):
        assert tb.pkg_version('DoesNotExist') is None

class Test_is_localdb:  # NOSONAR
    def test_mslocal(self):
        assert tb.is_localdb(r'mssql://(LocalDB)\MSSQLLocalDB')  # NOSONAR

    def test_mslocal_no_scheme(self):
        assert tb.is_localdb(r'(LocalDB)\MSSQLLocalDB')

    def test_mysql(self):
        assert not tb.is_localdb(r'mysql://(LocalDB)\MSSQLLocalDB')

def test_dmap():
    result = {'a': typeint, 'b': typeint, 'c': typeint, 'd': typeint, 'e': typeint, 'f': typeint, 'g': typestr, 'h h': typestr, 9: typestr}
    assert tb.dmap(test.dict, keyfunc=type) == result

def test_cast_config():
    result = {'section': {'def_key': 'def_value', 'int': 1, 'float': 1.0, 'true': True, 'false': False, 'none': None, 'str': 'text'}}
    assert tb.cast_config(test.config) == result

def test_typeof():
    assert tb.typeof(test.set) == set

class Test_port_reachable:  # NOSONAR
    def test_reachable(self):
        server = socket.create_server(('localhost', 0))
        port   = server.getsockname()[1]
        assert tb.port_reachable(f'scheme://localhost:{port}')
        server.close()

    def test_mslocal(self):
        assert tb.port_reachable(r'mssql://(LocalDB)\MSSQLLocalDB')  # NOSONAR

    def test_default_port(self):
        server = socket.create_server(('localhost', 1521))
        assert tb.port_reachable('oracle://localhost')
        server.close()

    def test_unreachable(self):
        assert not tb.port_reachable('scheme://localhost:1')

    def test_no_port_unknown_scheme(self):
        match = '^no port given and can\'t find default port for scheme "scheme"$'
        with pytest.raises(ValueError, match=match):
            tb.port_reachable('scheme://')

    def test_no_scheme(self):
        with pytest.raises(ValueError, match='^no URL scheme given$'):
            tb.port_reachable('liteloc')

# DATA #
class Test_groupby:  # NOSONAR
    def test_dict(self):
        group  = tb.groupby(test.dict, keyfunc=lambda x: type(x[1]))
        result = {typeint: {'a': 1, 'b': 2, 'c': 3, 'd': 4, 'e': 5, 'f': 6}, typestr: {9: '', 'g': '7', 'h h': '8 8'}}
        assert group == result

    def test_list(self):
        group = tb.groupby(test.list, keyfunc=type)
        assert group == {typeint: [1, 2, 3, 4, 5, 6], typestr: ['7', '8 8', '']}

    def test_set(self):
        group = tb.groupby(test.set, keyfunc=type)
        assert group == {typeint: {1, 2, 3, 4, 5, 6}, typestr: {'7', '8 8', ''}}

    def test_tuple(self):
        group = tb.groupby(test.tuple, keyfunc=type)
        assert group == {typeint: (1, 2, 3, 4, 5, 6), typestr: ('7', '8 8', '')}

    def test_error_label(self):
        with pytest.raises(TypeError, match='^axis specified but iterable is not dataframe$'):
            tb.groupby(test.sr, axis='rows')

    def test_error_axis(self):
        with pytest.raises(ValueError, match="^axis must be 'rows' or 'columns'$"):
            tb.groupby(test.df, axis='row')

    def test_series(self):
        group  = tb.groupby(test.sr, keyfunc=type)
        result = {typeint: ['a', 'b', 'c', 'd', 'e', 'f'], typestr: ['g', 'h', 'i']}
        assert groups_lst(group) == result

    def test_dataframe_group_by_row(self):
        group = tb.groupby(test.df, keyfunc=lambda x: test.even(x['e']), axis='rows')
        assert groups_lst(group) == {False: [1, 3], True: [2, 4]}

    def test_dataframe_group_by_column(self):
        group = tb.groupby(test.df, keyfunc=lambda x: type(x[1]), axis='columns')
        assert groups_lst(group) == {float: ['d'], int: ['e'], str: ['a', 'b', 'c']}

    def test_error_type(self):
        match = r'^Type not supported for iterable\. Use dictionary, list, set, tuple, series, or dataframe\.$'
        with pytest.raises(TypeError, match=match):
            tb.groupby(test.str)

def test_sort_index():
    result = collections.OrderedDict([(9, ''), ('a', 1), ('b', 2), ('c', 3), ('d', 4), ('e', 5), ('f', 6), ('g', '7'), ('h h', '8 8')])
    assert tb.sort_index(test.dict, keyfunc=str) == result

def test_sort_value():
    result = collections.OrderedDict([(9, ''), ('a', 1), ('b', 2), ('c', 3), ('d', 4), ('e', 5), ('f', 6), ('g', '7'), ('h h', '8 8')])
    assert tb.sort_value(test.dict, keyfunc=str) == result

# SQLALCHEMY #
class Test_engine:  # NOSONAR
    def test_mslocal(self):
        result = r'Engine(mssql://(LocalDB)\MSSQLLocalDB?Encrypt=no&TrustServerCertificate=yes&driver=ODBC+Driver+17+for+SQL+Server)'
        assert str(tb.engine(r'mssql://(LocalDB)\MSSQLLocalDB')) == result

    def test_mslinux(self):
        result = 'Engine(mssql://?Encrypt=yes&TrustServerCertificate=yes&driver=ODBC+Driver+17+for+SQL+Server)'
        assert str(tb.engine('mssql://')) == result

    def test_mylocal(self):
        assert str(tb.engine('mysql://')) == 'Engine(mysql+mysqlconnector://)'

    def test_oracle(self):
        assert str(tb.engine('oracle://')) == 'Engine(oracle:///?encoding=UTF-8&nencoding=UTF-8)'

    def test_oracle_sys(self):
        result = 'Engine(oracle://sys@/?encoding=UTF-8&mode=sysdba&nencoding=UTF-8)'
        assert str(tb.engine('oracle://sys@')) == result

    def test_postgresql(self):
        assert str(tb.engine('postgresql://')) == 'Engine(postgresql://)'

    def test_sqlite(self):
        assert str(tb.engine('sqlite:///')) == 'Engine(sqlite:///)'

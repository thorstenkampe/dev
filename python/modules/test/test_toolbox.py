# pytest
# pylint: disable = too-few-public-methods
import collections, pip, socket
import pytest
import test, toolbox as tb

class Test_pkg_version:  # NOSONAR
    def test_installed_current(self):
        assert tb.pkg_version('pip', type_='current') == pip.__version__

    def test_not_installed_current(self):
        assert tb.pkg_version('DoesNotExist', type_='current') is None

    def test_installed_latest(self):
        assert tb.pkg_version('pip', type_='latest') == pip.__version__

    def test_not_installed_latest(self):
        with pytest.raises(KeyError, match="^'info'$"):
            tb.pkg_version('DoesNotExist', type_='latest')

class Test_is_localdb:  # NOSONAR
    def test_mslocal(self):
        assert tb.is_localdb(r'mssql://(LocalDB)\MSSQLLocalDB')  # NOSONAR

    def test_mslocal_no_scheme(self):
        assert tb.is_localdb(r'(LocalDB)\MSSQLLocalDB')

    def test_mysql(self):
        assert not tb.is_localdb(r'mysql://(LocalDB)\MSSQLLocalDB')

def test_is_ipython_terminal():
    assert tb.is_ipython_terminal() is False

def test_dmap():
    result = {'a': int, 'b': int, 'c': int, 'd': int, 'e': int, 'f': int, 'g': str, 'h h': str, 9: str}
    assert tb.dmap(test.dict, keyfunc=type) == result

def test_cast():
    assert tb.dmap(test.section, tb.cast) == {'def_key': 'def_value', 'int': 1, 'float': 1.0, 'true': True, 'false': False, 'none': None, 'str': 'text'}

class Test_http_status_code:  # NOSONAR
    def test_url(self):
        assert tb.http_status_code('https://httpstat.us/403') == 403

    def test_url_with_port(self):
        assert tb.http_status_code('https://httpstat.us:443/403') == 403

def test_transpose():
    result = [('1a', '2a', '3a', '4a'), ('1b', '2b', '3b', '4b'), ('1c', '2c', '3c', '4c'), (1.0, 2.0, 3.0, 4.0), (1, 2, 3, 4)]
    assert tb.transpose(test.table) == result

class Test_port_reachable:  # NOSONAR
    def test_reachable(self):
        server = socket.create_server(('localhost', 0))
        port   = server.getsockname()[1]
        assert tb.port_reachable('localhost', port)
        server.close()

    def test_unreachable(self):
        assert not tb.port_reachable('localhost', 1)

# DATA #
class Test_groupby:  # NOSONAR
    def test_dict(self):
        group  = tb.groupby(test.dict, keyfunc=lambda x: type(x[1]))
        assert group == {int: {'a': 1, 'b': 2, 'c': 3, 'd': 4, 'e': 5, 'f': 6}, str: {9: '', 'g': '7', 'h h': '8 8'}}

    def test_list(self):
        group = tb.groupby(test.list, keyfunc=type)
        assert group == {int: [1, 2, 3, 4, 5, 6], str: ['7', '8 8', '']}

    def test_set(self):
        group = tb.groupby(test.set, keyfunc=type)
        assert group == {int: {1, 2, 3, 4, 5, 6}, str: {'7', '8 8', ''}}

    def test_tuple(self):
        group = tb.groupby(test.tuple, keyfunc=type)
        assert group == {int: (1, 2, 3, 4, 5, 6), str: ('7', '8 8', '')}

    def test_error_label(self):
        with pytest.raises(TypeError, match='^axis specified but iterable is not dataframe$'):
            tb.groupby(test.sr, axis='rows')

    def test_error_axis(self):
        with pytest.raises(ValueError, match="^axis must be 'rows' or 'columns'$"):
            tb.groupby(test.df, axis='row')

    def test_series(self):
        group  = tb.groupby(test.sr, keyfunc=type)
        assert tb.groups_lst(group) == {int: ['a', 'b', 'c', 'd', 'e', 'f'], str: ['g', 'h', 'i']}

    def test_dataframe_group_by_row(self):
        group = tb.groupby(test.df, keyfunc=lambda x: test.even(x['e']), axis='rows')
        assert tb.groups_lst(group) == {False: [1, 3], True: [2, 4]}

    def test_dataframe_group_by_column(self):
        group = tb.groupby(test.df, keyfunc=lambda x: type(x[1]), axis='columns')
        assert tb.groups_lst(group) == {float: ['d'], int: ['e'], str: ['a', 'b', 'c']}

    def test_error_type(self):
        match = r'^Type not supported for iterable\. Use dictionary, list, set, tuple, series, or dataframe\.$'
        with pytest.raises(TypeError, match=match):
            tb.groupby(test.str)

def test_groups_lst():
    assert tb.groups_lst(test.group) == {False: [1, 3], True: [2, 4]}

# SQLALCHEMY #
class Test_engine:  # NOSONAR
    def test_mslocal(self):
        result = r'Engine(mssql://(LocalDB)\MSSQLLocalDB?Encrypt=no&TrustServerCertificate=yes&driver=ODBC+Driver+18+for+SQL+Server&timeout=5)'
        assert str(tb.engine(r'mssql://(LocalDB)\MSSQLLocalDB')) == result

    def test_mslinux(self):
        assert str(tb.engine('mssql://')) == 'Engine(mssql://?Encrypt=yes&TrustServerCertificate=yes&driver=ODBC+Driver+18+for+SQL+Server&timeout=5)'

    def test_mylocal(self):
        assert str(tb.engine('mysql://')) == 'Engine(mysql+mysqlconnector://)'

    def test_oracle(self):
        assert str(tb.engine('oracle://')) == 'Engine(oracle+oracledb:///?encoding=UTF-8&nencoding=UTF-8)'

    def test_oracle_sys(self):
        assert str(tb.engine('oracle://sys@')) == 'Engine(oracle+oracledb://sys@/?encoding=UTF-8&mode=sysdba&nencoding=UTF-8)'

    def test_postgresql(self):
        assert str(tb.engine('postgresql://')) == 'Engine(postgresql+psycopg://)'

    def test_sqlite(self):
        assert str(tb.engine('sqlite:///')) == 'Engine(sqlite:///)'

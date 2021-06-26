# pytest
# pylint: disable = too-few-public-methods
import re
import pip, pycompat
from socket  import create_server
from pytest  import raises
from test    import config, even, dict as dict_, set as set_
from toolbox import *  # NOSONAR

def test_file_version():
    winfile   = r'\scoop\apps\miniconda3\current\envs\main\python.exe'
    linuxfile = '/libpython3.8.so.1.0'
    if pycompat.system.is_windows:
        match = r'3\.\d{1,2}\.\d{3,4}\.\d{4}'  # 3.9.150.1013
        assert re.fullmatch(match, file_version(winfile))
    else:
        assert file_version(linuxfile) == '3.8.1.0'

class Test_pkg_version:  # NOSONAR
    def test_installed(self):
        assert pkg_version('pip') == pip.__version__

    def test_not_installed(self):
        assert pkg_version('DoesNotExist') is None

def test_latest_version():
    assert latest_version('pip-install-test') == '0.5'

class Test_is_localdb:  # NOSONAR
    def test_mslocal(self):
        assert is_localdb(r'mssql://(LocalDB)\MSSQLLocalDB')

    def test_mslocal_no_scheme(self):
        assert is_localdb(r'(LocalDB)\MSSQLLocalDB')

    def test_mysql(self):
        assert not is_localdb(r'mysql://(LocalDB)\MSSQLLocalDB')

def test_remove_ansi():
    color_string = "\x1b[01;31mCRITICAL\x1b[0m: can't find file type\x1b[0m"
    assert remove_ansi(color_string) == "CRITICAL: can't find file type"

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
        match = '^no URL scheme given$'
        with raises(ValueError, match=match):
            host_reachable('liteloc')

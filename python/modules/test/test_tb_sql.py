# pylint: disable = too-few-public-methods
from tb_sql import *  # NOSONAR

class Test_islocaldb:  # NOSONAR
    def test_mslocal(self):
        assert islocaldb(r'mssql://(LocalDB)\MSSQLLocalDB')

    def test_mslinux(self):
        assert not islocaldb('mssql://')

class Test_engine:  # NOSONAR
    def test_mslocal(self):
        result = r'Engine(mssql://(LocalDB)\MSSQLLocalDB?driver=ODBC+Driver+17+for+SQL+Server;Encrypt=no;TrustServerCertificate=yes)'
        assert str(engine(r'mssql://(LocalDB)\MSSQLLocalDB')) == result

    def test_mslinux(self):
        result = 'Engine(mssql://?driver=ODBC+Driver+17+for+SQL+Server;Encrypt=yes;TrustServerCertificate=yes)'
        assert str(engine('mssql://')) == result

    def test_mylocal(self):
        assert str(engine('mysql://')) == 'Engine(mysql+mysqlconnector://?)'

    def test_oracle(self):
        result = 'Engine(oracle:///?encoding=UTF-8&nencoding=UTF-8)'
        assert str(engine('oracle://')) == result

    def test_oracle_sys(self):
        result = 'Engine(oracle://sys@/?encoding=UTF-8&mode=sysdba&nencoding=UTF-8)'
        assert str(engine('oracle://sys@')) == result

    def test_postgresql(self):
        assert str(engine('postgresql://')) == 'Engine(postgresql://?)'

    def test_sqlite(self):
        assert str(engine('sqlite:///')) == 'Engine(sqlite:///)'

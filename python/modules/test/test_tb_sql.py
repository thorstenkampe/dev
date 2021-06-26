# pytest
# pylint: disable = too-few-public-methods
from tb_sql import *  # NOSONAR

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
        result = 'Engine(oracle:///?encoding=UTF-8&nencoding=UTF-8)'
        assert str(engine('oracle://')) == result

    def test_oracle_sys(self):
        result = 'Engine(oracle://sys@/?encoding=UTF-8&mode=sysdba&nencoding=UTF-8)'
        assert str(engine('oracle://sys@')) == result

    def test_postgresql(self):
        assert str(engine('postgresql://')) == 'Engine(postgresql://)'

    def test_sqlite(self):
        assert str(engine('sqlite:///')) == 'Engine(sqlite:///)'

# pylint: disable = too-few-public-methods
from collections import OrderedDict
from pytest      import raises
from test        import (df, dict as dict_, even, groups_lst, list as list_, set as set_,
                         sr, str as str_, table, tuple as tuple_)
from tb_data     import *  # NOSONAR

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
        match = '^axis specified but iterable is not dataframe$'
        with raises(TypeError, match=match):
            groupby(sr, axis='rows')

    def test_error_axis(self):
        match = "^axis must be 'rows' or 'columns'$"
        with raises(ValueError, match=match):
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

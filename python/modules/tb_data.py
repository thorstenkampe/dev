import toolbox as tb
from collections     import defaultdict, OrderedDict
from collections.abc import MappingView
from pandas          import DataFrame, Series

def dfsplit(df):
    return df.to_dict(orient='split')

def shape(seq):
    dimension = tuple()
    # MappingView is any of dict.items(), keys(), values()
    while tb.typeof(seq) in (MappingView, list, tuple):
        dimension += (len(seq), )
        try:
            seq = list(seq)[0]
        except IndexError:  # sequence is empty
            break
    return dimension

def sort_index(dict_, keyfunc=tb.ident):
    '''sort dictionary by index (dictionary key)'''
    return OrderedDict(sorted(dict_.items(), key=lambda kv: keyfunc(kv[0])))

def sort_value(dict_, keyfunc=tb.ident):
    '''sort dictionary by value'''
    return OrderedDict(sorted(dict_.items(), key=lambda kv: keyfunc(kv[1])))

def groupby(iter_, keyfunc=tb.ident, axis=None):
    '''group iterable into equivalence classes - see http://en.wikipedia.org/wiki/Equivalence_relation'''
    type_    = tb.typeof(iter_)
    eq_class = defaultdict(type_)

    if axis and type_ != DataFrame:
        raise TypeError('axis specified but iterable is not dataframe')

    if axis not in [None, 'rows', 'columns']:
        raise ValueError("axis must be 'rows' or 'columns'")

    if   type_ == dict:
        iter_ = iter_.items()

        def grouper(proj, elem):
            eq_class[proj][elem[0]] = elem[1]

    elif type_ == list:
        def grouper(proj, elem):
            eq_class[proj].append(elem)

    elif type_ == set:
        def grouper(proj, elem):
            eq_class[proj].add(elem)

    elif type_ == tuple:
        def grouper(proj, elem):
            eq_class[proj] += (elem,)

    elif type_ == Series:
        return iter_.groupby(iter_.apply(keyfunc), axis='index', sort=False)

    # https://realpython.com/pandas-groupby/
    elif type_ == DataFrame:
        if axis == 'columns':
            iter_ = iter_.transpose()  # = apply by axis=rows, groupby by axis=columns
        return iter_.groupby(iter_.apply(keyfunc, axis='columns'), axis='index', sort=False)

    else:
        msg = ('Type not supported for iterable. Use dictionary, list, set, tuple,'
               ' series, or dataframe.')
        raise TypeError(msg)

    for proj, elem in zip(map(keyfunc, iter_), iter_):
        grouper(proj, elem)

    return dict(eq_class)

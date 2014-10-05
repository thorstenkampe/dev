# coding: utf-8
from __future__ import (
    division         as _division,
    print_function   as _print_function,
    unicode_literals as _unicode_literals)

import collections as _collections, \
       itertools   as _itertools,   \
       math        as _math,        \
       operator    as _operator

##region COMBINATIONS AND PERMUTATIONS##
def _comb(n, k):
    return _math.factorial(n) // (_math.factorial(k) * _math.factorial(n - k))

def _perm(n, k):
    return _math.factorial(n) // _math.factorial(n - k)

def combination (seq_or_n, k, repeat = False):
    # combinations are unordered
    if repeat is False:
        try:
            return _itertools.combinations(seq_or_n, k)
        except TypeError:
            return _comb(seq_or_n, k)

    elif repeat is True:
        try:
            return _itertools.combinations_with_replacement(seq_or_n, k)
        except TypeError:
            return _comb(seq_or_n + k - 1, k)

def permutation(seq_or_n, k, repeat = False):
    # permutations are ordered
    # k-permutations are sometimes called variations and then only
    # "full" n-permutations without replacement are called permutations
    # http://de.wikipedia.org/wiki/Abzählende_Kombinatorik#Begriffsabgrenzungen
    if repeat is False:
        try:
            return _itertools.permutations(seq_or_n, k)
        except TypeError:
            return _perm(seq_or_n, k)

    elif repeat is True:
        try:
            return _itertools.product(seq_or_n, repeat = k)
        except TypeError:
            return seq_or_n ** k
#endregion

##region MULTISETS ##
class MultiSet(object):
    """Set operations on multisets"""
    def __init__(inst, seq1, seq2):
        inst._seq1 = seq1
        inst._seq2 = seq2

    def union(inst):
        return (_collections.Counter(inst._seq1) |
                _collections.Counter(inst._seq2)).elements()

    def intersection(inst):
        return (_collections.Counter(inst._seq1) &
                _collections.Counter(inst._seq2)).elements()

    def difference(inst):
        return (_collections.Counter(inst._seq1) -
                _collections.Counter(inst._seq2)).elements()

    def symmetric_difference(inst):
        return MultiSet(inst.union(), inst.intersection()).difference()
#endregion

##region QUOTIENTSET##
def _ident(x):
    return x

class QuotientSet(object):
    """
    partition seq into equivalence classes
    see http://en.wikipedia.org/wiki/Equivalence_relation

    What are the most common word lengths in word list of 310,000 words?
    >>> qs = QuotientSet(bigstring.splitlines(), len)
    >>> DictMethods(qs.count()).sort(sortby = 'value')
    OrderedDict([... (8, 43555), (10, 46919), (9, 48228)])
    """

    def __init__(inst, seq, keyfunc = _ident):
        inst._seq       = seq
        inst._canonproj = keyfunc
        try:
            inst._qs = inst._qshashable()
        except TypeError:
            try:
                inst._qs = inst._qsorderable()
            except TypeError as exception:
                inst._qs        = inst._qsunorderable()
                inst._exception = exception

    def _qshashable(inst):
        qs = _collections.defaultdict(list)
        for obj in inst._seq:
            qs[inst._canonproj(obj)].append(obj)
        return dict(qs)

    def _qsorderable(inst):
        return [(proj_value, list(equiv_class))
                for proj_value, equiv_class in
                _itertools.groupby(sorted(
                    inst._seq, key = inst._canonproj), inst._canonproj)]

    def _qsunorderable(inst):
        qs          = []
        proj_values = []

        for obj in inst._seq:
            proj_value = inst._canonproj(obj)
            try:
                qs[proj_values.index(proj_value)].append(obj)
            except ValueError:
                qs.append([obj])
                proj_values.append(proj_value)
        return list(zip(proj_values, qs))

    def count(inst):
        if isinstance(inst._qs, dict):
            return DictMethods(inst._qs).count()
        else:
            return DictItems(inst._qs).count()

    def equivalenceclass(inst, key):
        if isinstance(inst._qs, dict):
            return inst._qs[key]
        else:
            return DictItems(inst._qs)[key]

    def max(inst):
        if isinstance(inst._qs, dict):
            return DictMethods(inst._qs).max()
        else:
            try:
                # `_exception` exists, that means dictitem could not be ordered
                raise TypeError(inst._exception)
            except AttributeError:
                # dictitem is already sorted, so we just take the last element as slice
                return inst._qs[-1:]

    def min(inst):
        if isinstance(inst._qs, dict):
            return DictMethods(inst._qs).min()
        else:
            try:
                # `_exception` exists, that means dictitem could not be ordered
                raise TypeError(inst._exception)
            except AttributeError:
                # dictitem is already sorted, so we just take the first element as slice
                return inst._qs[:1]

    def sort(inst):
        if isinstance(inst._qs, dict):
            return DictMethods(inst._qs).sort()
        else:
            try:
                # `_exception` exists, that means dictitem could not be ordered
                raise TypeError(inst._exception)
            except AttributeError:
                # dictitem is already sorted
                return inst._qs

    def partition(inst):
        if isinstance(inst._qs, dict):
            return inst._qs.values()
        else:
            return DictItems(inst._qs).values()

    def quotientset(inst):
        return inst._qs
#endregion

##region DICTITEMS##
class DictItems(object):
    def __init__(inst, dictitems):
        inst._items = dictitems

    def __getitem__(inst, key):
        return inst.values()[inst.keys().index(key)]

    def _extremum(inst, min_or_max, key = 'key'):
        if key == 'key':
            return [min_or_max(inst._items)]
        else:
            return min_or_max(inst.values())

    def max(inst, key = 'key'):
        return inst._extremum(max, key = key)

    def min(inst, key = 'key'):
        return inst._extremum(min, key = key)

    def sort(inst, sortby = 'key'):
        """sort by key or value"""
        return sorted(
            inst._items, key = _operator.itemgetter(sortby == 'value'))

    def items(inst):
        return inst._items

    def keys(inst):
        return list(zip(*inst._items))[0]

    def values(inst):
        return list(zip(*inst._items))[1]

    def count(inst):
        """returns the count of a multidictitem"""
        return [(key, len(values)) for key, values in inst._items]
#endregion

##region DICTMETHODS ##
class DictMethods(object):
    def __init__(inst, adict):
        inst._adict = adict

    def _extremum(inst, min_or_max, key = 'key'):
        if key == 'key':
            extremum = min_or_max(inst._adict)
            return {extremum: inst._adict[extremum]}
        else:
            return min_or_max(inst._adict.values())

    def max(inst, key = 'key'):
        return inst._extremum(max, key = key)

    def min(inst, key = 'key'):
        return inst._extremum(min, key = key)

    def sort(inst, sortby = 'key'):
        """sort dictionary by key or value"""
        return _collections.OrderedDict(
               sorted(inst._adict.items(), key = _operator.itemgetter(sortby == 'value')))

    def count(inst):
        """returns the count of a multidict"""
        return {key: len(inst._adict[key]) for key in inst._adict}
#endregion

##region MISCELLANEOUS##
def cartes(seq0, seq1):
    """return the Cartesian Product of two sequences"""
    # "single column" sequences have to be specified as [item] or (item,) - not (item)
    return [item0 + item1 for item0 in seq0 for item1 in seq1]

def makeset(seq):
    """make seq a true set by removing duplicates"""
    try:
        return set(seq)
    except TypeError:  # seq has unhashable elements
        return [part[0] for part in QuotientSet(seq).partition()]

def partition(seq, split):
    if isinstance(split, int):
        return partition(seq, [split] * (len(seq) // split))

    elif isinstance(split[0], int):
        part = []
        for slice in split:
            part.append(seq[:slice])
            seq = seq[slice:]

        if seq:
            part += [seq]

        return part

    elif isinstance(split[0], str):
        for separator in split[1:]:
            seq = seq.replace(separator, split[0])
        return seq.split(split[0])
#endregion

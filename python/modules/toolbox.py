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

class Comb(object):
    def __init__(inst, seq_or_n):
        inst._seq_or_n = seq_or_n

    def comb (inst, k, repeat = False):
        # combinations are unordered
        if repeat is False:
            try:
                return _itertools.combinations(inst._seq_or_n, k)
            except TypeError:
                return _comb(inst._seq_or_n, k)

        elif repeat is True:
            try:
                return _itertools.combinations_with_replacement(inst._seq_or_n, k)
            except TypeError:
                return _comb(inst._seq_or_n + k - 1, k)

    def perm(inst, k, repeat = False):
        # permutations are ordered
        # k-permutations are sometimes called variations and then only
        # "full" n-permutations without replacement are called permutations
        # http://de.wikipedia.org/wiki/Abzählende_Kombinatorik#Begriffsabgrenzungen
        if repeat is False:
            try:
                return _itertools.permutations(inst._seq_or_n, k)
            except TypeError:
                return _perm(inst._seq_or_n, k)

        elif repeat is True:
            try:
                return _itertools.product(inst._seq_or_n, repeat = k)
            except TypeError:
                return inst._seq_or_n ** k
#endregion

##region MULTISET ##
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
    >>> GenericDict(qs.count()).sort(sortby = 'value')
    OrderedDict([... (8, 43555), (10, 46919), (9, 48228)])
    """

    def __init__(inst, seq, keyfunc = _ident):
        inst._seq       = seq
        inst._canonproj = keyfunc
        # we're dispatching on performance: hashable -> orderable, unorderable
        # (dictionary.get -> itertools.groupby, list.index)
        inst._qs = {}
        try:
            inst._qs = inst._qsinit()
        except TypeError:
            try:
                inst._qs = inst._qsorderable()
            except TypeError:
                inst._qs = []
                inst._qs = inst._qsinit()

    def _qsinit(inst):
        qs = GenericDict(inst._qs)
        for obj in inst._seq:
            qs.setdefault(inst._canonproj(obj), []).append(obj)
        return qs.items()

    def _qsorderable(inst):
        qs = _itertools.groupby(sorted(inst._seq, key = inst._canonproj), inst._canonproj)
        return [(proj_value, list(equiv_class)) for proj_value, equiv_class in qs]

    def count(inst):
        return MultiDict(inst._qs).count()

    def equivalenceclass(inst, key):
        return GenericDict(inst._qs)[key]

    def partition(inst):
        return GenericDict(inst._qs).values()

    def quotientset(inst):
        return inst._qs

    # if `qs` is a dictitem, it is already sorted or cannot be sorted
    # if `qs` is a dictionary, it is likely already displayed sorted
    # possible optimizations:
    # - return first/last slice for `min`/`max`
    # - return the already sorted list for `sort`
    def max(inst):
        return GenericDict(inst._qs).max()

    def min(inst):
        return GenericDict(inst._qs).min()

    def sort(inst):
        return GenericDict(inst._qs).sort()
#endregion

##region DICTIONARY ##
class GenericDict(object):
    """a GenericDict is a dictionary or a dictitem"""
    def __init__(inst, generic_dict):
        inst._generic = generic_dict

    def __getitem__(inst, key):
        if isinstance(inst._generic, dict):
            return inst._generic[key]
        else:
            return inst.values()[inst.keys().index(key)]

    def setdefault(inst, key, default = None):
        if isinstance(inst._generic, dict):
            return inst._generic.setdefault(key, default)
        else:
            try:
                return inst.__getitem__(key)
            except ValueError:
                inst._generic.append((key, default))
                return default

    def values(inst):
        if isinstance(inst._generic, dict):
            return inst._generic.values()
        else:
            try:
                return list(zip(*inst._generic))[1]
            except IndexError:  # empty GenericDict
                return ()

    def keys(inst):
            try:
                return list(zip(*inst._generic))[0]  # dictitem only
            except IndexError:  # empty GenericDict
                return ()

    def items(inst):
            return inst._generic

    def sort(inst, sortby = 'key'):
        """sort by key or value"""
        if isinstance(inst._generic, dict):
            return _collections.OrderedDict(sorted(
                inst._generic.items(), key = _operator.itemgetter(sortby == 'value')))
        else:
            return sorted(
                inst._generic, key = _operator.itemgetter(sortby == 'value'))

    def _extremum(inst, min_or_max, key = 'key'):
        """
        returns `{key: value}` or `[(key, value)]` for `key = key` and
        `value` for `key = value` (as opposed to a standard dictionary).
        The former is more useful in my opinion and the latter necessary
        because dict values are not necessarily unique.
        """
        if isinstance(inst._generic, dict):
            if key == 'key':
                extremum = min_or_max(inst._generic)
                return {extremum: inst._generic[extremum]}
            else:
                return min_or_max(inst._generic.values())
        else:
            if key == 'key':
                return [min_or_max(inst._generic)]
            else:
                return min_or_max(inst.values())

    def max(inst, key = 'key'):
        return inst._extremum(max, key = key)

    def min(inst, key = 'key'):
        return inst._extremum(min, key = key)

class MultiDict(object):
    def __init__(inst, multidict):
        inst._multi = multidict

    def count(inst):
        """returns the count of a multidict"""
        if isinstance(inst._multi, dict):
            return {key: len(inst._multi[key]) for key in inst._multi}
        else:
            return [(key, len(values)) for key, values in inst._multi]
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

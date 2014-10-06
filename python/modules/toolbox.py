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
        inst._issorted  = False
        try:
            inst._qs = inst._qshashable()
        except TypeError:
            try:
                inst._qs       = inst._qsorderable()
                inst._issorted = True
            except TypeError:
                inst._qs = inst._qsunorderable()

    def _qshashable(inst):
        qs = _collections.defaultdict(list)
        for obj in inst._seq:
            qs[inst._canonproj(obj)].append(obj)
        return dict(qs)

    def _qsorderable(inst):
        qs = _itertools.groupby(sorted(inst._seq, key = inst._canonproj), inst._canonproj)
        return [(proj_value, list(equiv_class)) for proj_value, equiv_class in qs]

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
        return GenericDict(inst._qs).count()

    def equivalenceclass(inst, key):
        return GenericDict(inst._qs)[key]

    def max(inst):
        if inst._issorted:
            return inst._qs[-1:]  # last element as slice
        else:
            return GenericDict(inst._qs).max()

    def min(inst):
        if inst._issorted:
            return inst._qs[:1]   # first element as slice
        else:
            return GenericDict(inst._qs).min()

    def sort(inst):
        if inst._issorted:
            return inst._qs
        else:
            return GenericDict(inst._qs).sort()

    def partition(inst):
        return GenericDict(inst._qs).values()

    def quotientset(inst):
        return inst._qs
#endregion

##region GENERICDICT ##
class GenericDict(object):
    def __init__(inst, generic_dict):
        inst._generic = generic_dict

    def __getitem__(inst, key):
        if isinstance(inst._generic, dict):
            return inst._generic[key]
        else:
            return inst.values()[inst.keys().index(key)]

    def values(inst):
        if isinstance(inst._generic, dict):
            return inst._generic.values()
        else:
            return list(zip(*inst._generic))[1]

    def keys(inst):
            return list(zip(*inst._generic))[0]  # dictitem only

    def items(inst):
            return inst._generic                 # dictitem only

    def count(inst):
        """returns the count of a multidictitem"""
        if isinstance(inst._generic, dict):
            return {key: len(inst._generic[key]) for key in inst._generic}
        else:
            return [(key, len(values)) for key, values in inst._generic]

    def sort(inst, sortby = 'key'):
        """sort by key or value"""
        if isinstance(inst._generic, dict):
            return _collections.OrderedDict(sorted(
                inst._generic.items(), key = _operator.itemgetter(sortby == 'value')))
        else:
            return sorted(
                inst._generic, key = _operator.itemgetter(sortby == 'value'))

    def _extremum(inst, min_or_max, key = 'key'):
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

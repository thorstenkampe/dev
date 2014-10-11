# coding: utf-8

##region IMPORTS ##
from __future__ import (
    division         as _division,
    print_function   as _print_function,
    unicode_literals as _unicode_literals)

import collections as _collections  ## QUOTIENTSET
import itertools   as _itertools    ## QUOTIENTSET
import operator    as _operator     ## QUOTIENTSET
#endregion

##region QUOTIENTSET ##
def _ident(x):
    return x

class QuotientSet:
    """
    partition seq into equivalence classes
    see http://en.wikipedia.org/wiki/Equivalence_relation

    What are the most common word lengths in word list of 310,000 words?
    >>> from testing import *
    >>> qs = QuotientSet(bigstring.splitlines(), len)
    >>> count = MultiDict(qs.quotientset()).count()
    >>> GenericDict(count).sort(sortby = 'value')  # doctest: +ELLIPSIS
    OrderedDict([... (8, 43555), (10, 46919), (9, 48228)])
    """

    def __init__(inst, seq, keyfunc = _ident):
        inst._seq       = seq
        inst._canonmap = keyfunc
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
            qs.setdefault(inst._canonmap(obj), []).append(obj)
        return qs.items()

    def _qsorderable(inst):
        qs = _itertools.groupby(sorted(inst._seq, key = inst._canonmap), inst._canonmap)
        return [(proj_value, list(equiv_class)) for proj_value, equiv_class in qs]

    def equivalenceclass(inst, key):
        return GenericDict(inst._qs)[key]

    def partition(inst):
        return GenericDict(inst._qs).values()

    def canonical_class(inst):
        return GenericDict(inst._qs).keys()

    def quotientset(inst):
        return inst._qs

    def representative_class(inst):
        """
        >>> def modulo2(x): return x % 2
        >>> QuotientSet([0, 1, 2, 3, 4], modulo2).representative_class()
        (0, 1)
        """
        return list(zip(*inst.partition()))[0]
#endregion

##region DICTIONARY ##
class GenericDict:
    """a GenericDict is a dictionary or a dictitem"""
    def __init__(inst, generic_dict):
        inst._generic = generic_dict

    def __getitem__(inst, key):
        if isinstance(inst._generic, dict):
            return inst._generic[key]
        else:
            return inst.values()[inst.keys().index(key)]

    # simple methods #
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
        if isinstance(inst._generic, dict):
            return inst._generic.keys()
        else:
            try:
                return list(zip(*inst._generic))[0]
            except IndexError:  # empty GenericDict
                return ()

    def items(inst):
            return inst._generic

    # higher level methods #
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

class MultiDict:
    def __init__(inst, multidict):
        inst._multi = multidict

    def count(inst):
        """returns the count of a multidict"""
        if isinstance(inst._multi, dict):
            return {key: len(inst._multi[key]) for key in inst._multi}
        else:
            return [(key, len(values)) for key, values in inst._multi]
#endregion

##region PARTITION ##
def partition(seq, split):
    """
    split sequence by length or string by separator

    >>> list = ['a', 'b', 'c', 'd', 'e']
    >>> partition(list, 2)
    [['a', 'b'], ['c', 'd'], ['e']]
    >>> partition(list, [1, 2])
    [['a'], ['b', 'c'], ['d', 'e']]
    >>> string = 'The quick brown fox jumps over the lazy dog'
    >>> partition(string, [' ', 'the', 'The'])
    ['', '', 'quick', 'brown', 'fox', 'jumps', 'over', '', '', 'lazy', 'dog']
    """

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
##region IMPORTS ##
from __future__ import division, print_function, unicode_literals

import itertools              # UTILITIES
try: import collections.abc as abc
except ImportError: import collections as abc
import itertools              # EQUIVALENCE
import collections, operator  # GENERICDICT
#endregion

try:
    unicode
except NameError:
    unicode = str

##region SMALL FUNCTIONS ##
def ident(x):
    return x

def even(integer):
    return not(odd(integer))

def odd(integer):
    return bool(integer % 2)
#endregion

##region UTILITIES ##
def dim(seq):
    dimension = []
    while isinstance(seq, (list, tuple, abc.ValuesView)):
        dimension.append(len(seq))
        try:
            seq = list(seq)[0]
        except IndexError:  # sequence is empty
            break
    return dimension

def flatten(seq):
    for dimension in dim(seq)[1:]:
        seq = itertools.chain.from_iterable(seq)
    return list(seq)

def periodic(counter, counter_at_sop, sop, eop):
    """
    wrap counter in range(sop, eop + 1)
    sop = start of period; eop = end of period
    """
    return (counter - counter_at_sop) % (eop - sop + 1) + sop
#endregion

##region EQUIVALENCE ##
class Equivalence:
    """
    partition seq into equivalence classes
    see http://en.wikipedia.org/wiki/Equivalence_relation
    """
    def __init__(inst, seq, keyfunc = ident):
        inst._seq       = seq
        inst._invariant = keyfunc
        # we're dispatching on performance:
        # hashable -> orderable, unorderable (dictionary.get ->
        # itertools.groupby, list.index)
        inst._eq = {}
        try:
            inst._eq = inst._eqinit()
        except TypeError:
            try:
                inst._eq = inst._eqorderable()
            except TypeError:
                inst._eq = []
                inst._eq = inst._eqinit()

    def _eqinit(inst):
        eq = GenericDict(inst._eq)
        for obj in inst._seq:
            eq.setdefault(inst._invariant(obj), []).append(obj)
        return eq.items()

    def _eqorderable(inst):
        sorted_ = sorted(inst._seq, key = inst._invariant)
        eq      = itertools.groupby(sorted_, inst._invariant)
        return [(invariant, list(equiv_class)) for invariant, equiv_class in eq]

    # determines output of `instance` and `print(instance)`
    def __repr__(inst):
        return repr(inst._eq)

    #
    def quotientset(inst):
        """
        What are the most common word lengths in word list of 310,000 words?
        >>> eq = Equivalence(bigfile.read().splitlines(), len)  # doctest: +SKIP
        >>> count = MultiDict(eq.quotientset()).count()         # doctest: +SKIP
        >>> GenericDict(count).sort(sortby = 'value')           # doctest: +SKIP
        OrderedDict([... (8, 43555), (10, 46919), (9, 48228)])

        >>> seq_func = (11, 22, 33, 44), even
        >>> Equivalence(*seq_func).quotientset()
        {False: [11, 33], True: [22, 44]}
        """
        return inst._eq

    def partition(inst):
        """
        >>> seq_func = (11, 22, 33, 44), even
        >>> list(Equivalence(*seq_func).partition())
        [[11, 33], [22, 44]]
        """
        return GenericDict(inst._eq).values()

    def equivalence_class(inst, key):
        """
        >>> seq_func = (11, 22, 33, 44), even
        >>> Equivalence(*seq_func).equivalence_class(True)
        [22, 44]
        """
        return GenericDict(inst._eq)[key]

    def invariant_class(inst):
        """
        >>> seq_func = (11, 22, 33, 44), even
        >>> list(Equivalence(*seq_func).invariant_class())
        [False, True]
        """
        return GenericDict(inst._eq).keys()

    def representative_class(inst):
        """
        canonical representatives - first element of each equivalence
        class
        >>> seq_func = (11, 22, 33, 44), even
        >>> Equivalence(*seq_func).representative_class()
        (11, 22)
        """
        return list(zip(*inst.partition()))[0]
#endregion

##region GENERICDICT ##
class GenericDict:
    """
    a GenericDict is a dictionary or a list of tuples (when the keys
    are not hashable)
    """
    def __init__(inst, generic_dict):
        inst._generic = generic_dict

    def __getitem__(inst, key):
        if isinstance(inst._generic, dict):
            return inst._generic[key]
        else:
            return inst.values()[inst.keys().index(key)]

    # determines output of `instance` and `print(instance)`
    def __repr__(inst):
        return repr(inst._generic)

    # simple methods
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

    # higher level methods
    def sort(inst, sortby = 'key'):
        """sort by key or value"""
        key = operator.itemgetter(sortby == 'value')
        if isinstance(inst._generic, dict):
            sorted_ = sorted(inst._generic.items(), key = key)
            return collections.OrderedDict(sorted_)
        else:
            return sorted(inst._generic, key = key)

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
        """
        >>> smalldict = {1: '11', 2: '22', 4: '33', 3: '44'}
        >>> GenericDict(smalldict).max()
        {4: '33'}
        >>> GenericDict(smalldict).max(key = 'value')
        '44'
        """
        return inst._extremum(max, key = key)

    def min(inst, key = 'key'):
        return inst._extremum(min, key = key)
#endregion

##region MULTIDICT ##
class MultiDict:
    """a MultiDict is a GenericDict with multiple values"""
    def __init__(inst, multidict):
        inst._multi = multidict

    # determines output of `instance` and `print(instance)`
    def __repr__(inst):
        return repr(inst._multi)

    #
    def count(inst):
        """returns the count of a multidict
        >>> from pprint import pprint
        >>> smalltuple = (11, 22, 33, 44)
        >>> def evenodd(x): return 'even' if even(x) else 'odd'
        >>> eq = Equivalence(smalltuple, evenodd)
        >>> pprint(MultiDict(eq.quotientset()).count())
        {'even': 2, 'odd': 2}
        """
        if isinstance(inst._multi, dict):
            return {key: len(inst._multi[key]) for key in inst._multi}
        else:
            return [(key, len(values)) for key, values in inst._multi]
#endregion

##region PARTITION ##
def partition(seq, split):
    """
    split sequence by length or string by separator

    >>> smalllist = ['a', 'b', 'c', 'd', 'e']
    >>> partition(smalllist, 2)
    [['a', 'b'], ['c', 'd'], ['e']]
    >>> partition(smalllist, [1, 2])
    [['a'], ['b', 'c'], ['d', 'e']]
    >>> smallstring = 'The quick brown fox jumps over the lazy dog'
    >>> partition(smallstring, [' ', 'the', 'The'])
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

    elif isinstance(split[0], (str, unicode)):
        for separator in split[1:]:
            seq = seq.replace(separator, split[0])
        return seq.split(split[0])
    else:
        raise TypeError("Incorrect type for argument 'split' in partition(seq, split)")
#endregion

##region REGRESSION TESTS ##
__test__ = {
    'dim':         """
>>> from testing import makedimlist
>>> dim(makedimlist([2, 3, 4]))
[2, 3, 4]
                   """,

    'flatten':     """
>>> from testing import makedimlist
>>> flatten(makedimlist([2, 3, 4]))  # doctest: +ELLIPSIS
[0, 1, 2, 3, 4, 5, 6, 7, 8, ..., 16, 17, 18, 19, 20, 21, 22, 23]
                   """,

    'GenericDict': """
>>> from pprint import pprint
>>> from testing import smalldict, dictitem
>>> pprint(dict(GenericDict(smalldict)))
{1: '11', 2: '22', 3: '44', 4: '33'}
>>> GenericDict(dictitem)
[([1], '11'), ([2], '22'), ([4], '33'), ([3], '44')]
                   """
}
#endregion

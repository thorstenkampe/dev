##region SMALL FUNCTIONS ##
def ident(x):
    return x

def even(integer):
    return not(odd(integer))

def odd(integer):
    return bool(integer % 2)
#endregion

##region UTILITIES ##
import itertools, collections.abc

def dim(seq):
    """
    >>> from testing import makedimlist
    >>> dim(makedimlist([2, 3, 4]))
    [2, 3, 4]
    """
    dimension = []
    while isinstance(seq, (list, tuple, collections.abc.ValuesView)):
        dimension.append(len(seq))
        try:
            seq = list(seq)[0]
        except IndexError:  # sequence is empty
            break
    return dimension

def flatten(seq):
    """
    >>> from testing import makedimlist
    >>> flatten(makedimlist([2, 3, 4]))  # doctest: +ELLIPSIS
    [0, 1, 2, 3, 4, 5, 6, 7, 8, ..., 16, 17, 18, 19, 20, 21, 22, 23]
    """
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
import itertools

class Equivalence:
    """
    partition seq into equivalence classes
    see http://en.wikipedia.org/wiki/Equivalence_relation
    >>> from testing import unhashable, orderable, unorderable
    >>> Equivalence(unhashable)
    [(11, [11]), ([22], [[22]]), (33, [33])]
    >>> Equivalence(orderable)
    [([11], [[11]]), ([22], [[22]]), ([33], [[33]])]
    >>> Equivalence(unorderable)
    [(11, [11]), (['22'], [['22']]), (33, [33])]
    """
    def __init__(inst, seq, keyfunc = ident):

        def eq_init(type_):
            eq = GenericDict(type_())
            for obj in seq:
                eq.setdefault(keyfunc(obj), []).append(obj)
            return eq.items()

        # we're dispatching on performance...
        try:                   # hashable: dict.get
            inst._eq = eq_init(dict)
        except TypeError:
            try:               # orderable: itertools.groupby
                sorted_  = sorted(seq, key = keyfunc)
            except TypeError:  # unorderable: list.index
                inst._eq = eq_init(list)
            else:
                eq       = itertools.groupby(sorted_, keyfunc)
                inst._eq = [(invariant, list(equiv_class)) for invariant, equiv_class in eq]

    # determines output of `instance` and `print(instance)`
    def __repr__(inst):
        return repr(inst._eq)

    #
    def quotientset(inst):
        """
        >>> seq_func = (1, 2, 3, 4), even
        >>> Equivalence(*seq_func).quotientset()
        {False: [1, 3], True: [2, 4]}
        """
        return GenericDict(inst._eq)

    def partition(inst):
        """
        >>> seq_func = (1, 2, 3, 4), even
        >>> Equivalence(*seq_func).partition()
        [[1, 3], [2, 4]]
        """
        return list(GenericDict(inst._eq).values())

    def equivalence_class(inst, key):
        """
        >>> seq_func = (1, 2, 3, 4), even
        >>> Equivalence(*seq_func).equivalence_class(True)
        [2, 4]
        """
        return GenericDict(inst._eq)[key]

    def invariant_class(inst):
        """
        >>> seq_func = (1, 2, 3, 4), even
        >>> Equivalence(*seq_func).invariant_class()
        [False, True]
        """
        return list(GenericDict(inst._eq).keys())

    def representative_class(inst):
        """
        canonical representatives - first element of each equivalence
        class
        >>> seq_func = (1, 2, 3, 4), even
        >>> Equivalence(*seq_func).representative_class()
        [1, 2]
        """
        return [subset[0] for subset in inst.partition()]
#endregion

##region GENERICDICT ##
import collections

class GenericDict:
    """
    a GenericDict is a dictionary or a list of tuples (when the keys
    are not hashable)
    """
    def __init__(inst, generic_dict):
        inst._gd = generic_dict

    def __getitem__(inst, key):
        if isinstance(inst._gd, dict):
            return inst._gd[key]
        else:
            return inst.values()[inst.keys().index(key)]

    # determines output of `instance` and `print(instance)`
    def __repr__(inst):
        return repr(inst._gd)

    # simple methods
    def items(inst):
            return inst._gd

    def setdefault(inst, key, default = None):
        try:
            return inst._gd.setdefault(key, default)
        except AttributeError:
            try:
                return inst[key]
            except ValueError:
                inst._gd.append((key, default))
                return default

    def keys(inst):
        try:
            return inst._gd.keys()
        except AttributeError:
            return [key for key, value in inst._gd]

    def values(inst):
        try:
            return inst._gd.values()
        except AttributeError:
            return [value for key, value in inst._gd]

    # higher level methods
    def min_key(inst, keyfunc = ident):
        """
        >>> from testing import smalldict, dictitem
        >>> GenericDict(smalldict).min_key()
        1
        >>> GenericDict(dictitem).min_key()
        [1]
        """
        return min(inst.keys(), key = keyfunc)

    def min_value(inst, keyfunc = ident):
        """
        >>> from testing import smalldict, dictitem
        >>> GenericDict(smalldict).min_value(len)
        '4'
        >>> GenericDict(dictitem).min_value(len)
        '4'
        """
        return min(inst.values(), key = keyfunc)

    def max_key(inst, keyfunc = ident):
        return max(inst.keys(), key = keyfunc)

    def max_value(inst, keyfunc = ident):
        return max(inst.values(), key = keyfunc)

    def sort(inst, sortby, keyfunc = ident):
        """
        sort by key or value
        >>> from testing import smalldict, dictitem
        >>> GenericDict(smalldict).sort(sortby = 'key')
        OrderedDict([(1, '1111'), (2, '222'), (3, '4'), (4, '33')])
        >>> GenericDict(dictitem).sort(sortby = 'key')
        [([1], '1111'), ([2], '222'), ([3], '4'), ([4], '33')]
        >>> GenericDict(smalldict).sort(sortby = 'value', keyfunc = len)
        OrderedDict([(3, '4'), (4, '33'), (2, '222'), (1, '1111')])
        >>> GenericDict(dictitem).sort(sortby = 'value', keyfunc = len)
        [([3], '4'), ([4], '33'), ([2], '222'), ([1], '1111')]
        """
        if sortby not in ['key', 'value']:
            raise ValueError("'{}' not in ['key', 'value']".format(sortby))

        def keyfunc_(key_value):
            return keyfunc(key_value[sortby == 'value'])

        try:
            sorted_ = sorted(inst._gd.items(), key = keyfunc_)
        except AttributeError:
            return sorted(inst._gd, key = keyfunc_)
        else:
            return collections.OrderedDict(sorted_)
#endregion

##region PARTITION ##
def partition(seq, split):
    """
    split sequence by length or string by separator
    >>> list_ = ['a', 'b', 'c', 'd', 'e']
    >>> partition(list_, 2)
    [['a', 'b'], ['c', 'd'], ['e']]
    >>> partition(list_, [1, 2])
    [['a'], ['b', 'c'], ['d', 'e']]
    >>> string_ = 'The quick brown fox jumps over the lazy dog'
    >>> partition(string_, [' ', 'the', 'The'])
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
    else:
        raise TypeError("Incorrect type for argument 'split' in partition(seq, split)")
#endregion

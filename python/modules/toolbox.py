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
    >>> from testing import table
    >>> dim(table)
    [4, 5]
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
    >>> from testing import table
    >>> flatten(table)  # doctest: +ELLIPSIS
    ['a1', 'b1', 'c1', 'd1', 'e1', 'a2', ..., 'a4', 'b4', 'c4', 'd4', 'e4']
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
class Equivalence:
    """
    partition seq into equivalence classes
    see http://en.wikipedia.org/wiki/Equivalence_relation
    >>> from testing import hashable
    >>> Equivalence(hashable)
    {11: [11], '22': ['22'], 33: [33]}
    """
    def __init__(inst, seq, keyfunc = ident):

        eq = {}
        for obj in seq:
            eq.setdefault(keyfunc(obj), []).append(obj)
        inst._eq = eq

    # determines output of `instance` and `print(instance)`
    def __repr__(inst):
        return repr(inst._eq)

    #
    def quotientset(inst):
        """
        >>> eq = Equivalence([1, 2, 3, 4], even)
        >>> eq.quotientset()
        {False: [1, 3], True: [2, 4]}
        """
        return inst._eq

    def partition(inst):
        """
        >>> eq = Equivalence([1, 2, 3, 4], even)
        >>> eq.partition()
        [[1, 3], [2, 4]]
        """
        return list(inst._eq.values())

    def equivalence_class(inst, key):
        """
        >>> eq = Equivalence([1, 2, 3, 4], even)
        >>> eq.equivalence_class(True)
        [2, 4]
        """
        return inst._eq[key]

    def invariant_class(inst):
        """
        >>> eq = Equivalence([1, 2, 3, 4], even)
        >>> eq.invariant_class()
        [False, True]
        """
        return list(inst._eq.keys())

    def representative_class(inst):
        """
        canonical representatives - first element of each equivalence class
        >>> eq = Equivalence([1, 2, 3, 4], even)
        >>> eq.representative_class()
        [1, 2]
        """
        return [subset[0] for subset in inst.partition()]
#endregion

##region DICTIONARY ##
import collections

def min_key(dict_, keyfunc = ident):
    """
    >>> from testing import dict_
    >>> min_key(dict_)
    1
    """
    return min(dict_.keys(), key = keyfunc)

def min_value(dict_, keyfunc = ident):
    """
    >>> from testing import dict_
    >>> min_value(dict_, len)
    '4'
    """
    return min(dict_.values(), key = keyfunc)

def max_key(dict_, keyfunc = ident):
    """
    >>> from testing import dict_
    >>> max_key(dict_)
    4
    """
    return max(dict_.keys(), key = keyfunc)

def max_value(dict_, keyfunc = ident):
    """
    >>> from testing import dict_
    >>> max_value(dict_, len)
    '1111'
    """
    return max(dict_.values(), key = keyfunc)

def dictsort(dict_, sortby, keyfunc = ident):
    """
    sort by key or value
    >>> from testing import dict_
    >>> dictsort(dict_, sortby = 'key')
    OrderedDict([(1, '1111'), (2, '222'), (3, '4'), (4, '33')])
    >>> dictsort(dict_, sortby = 'value', keyfunc = len)
    OrderedDict([(3, '4'), (4, '33'), (2, '222'), (1, '1111')])
    """
    if sortby not in ['key', 'value']:
        raise ValueError(f"'{sortby}' not in ['key', 'value']")

    def keyfunc_(key_value):
        return keyfunc(key_value[sortby == 'value'])

    return collections.OrderedDict(sorted(dict_.items(), key = keyfunc_))

def count(dict_):
    """returns the count of a dictionary with multiple values
    >>> count({'odd': [11, 33], 'even': [22, 44]})
    {'odd': 2, 'even': 2}
    """
    return {key: len(dict_[key]) for key in dict_}
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
    else:
        raise TypeError("Incorrect type for argument 'split' in partition(seq, split)")
#endregion

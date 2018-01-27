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
        except TypeError:      # `keyfunc(obj)` is not hashable
            try:
                sorted_  = sorted(seq, key = keyfunc)
            except TypeError:  # unorderable: list.index
                inst._eq = eq_init(list)
            else:              # orderable: itertools.groupby
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
        canonical representatives - first element of each equivalence class
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
    a GenericDict is a dictionary or a list of tuples ("dictitem") if the keys
    are not hashable
    """
    def __init__(inst, generic_dict):
        inst._gd = generic_dict

    # determines `inst[key]`
    def __getitem__(inst, key):
        if isinstance(inst._gd, dict):
            return inst._gd[key]
        else:
            return inst.values()[inst.keys().index(key)]

    # determines output of `instance` and `print(instance)`
    def __repr__(inst):
        return repr(inst._gd)

    # make GenericDict iterable
    def __iter__(inst):
        return iter(inst._gd)

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
        >>> from testing import dict_, dictitem
        >>> GenericDict(dict_).min_key()
        1
        >>> GenericDict(dictitem).min_key()
        [1]
        """
        return min(inst.keys(), key = keyfunc)

    def min_value(inst, keyfunc = ident):
        """
        >>> from testing import dict_, dictitem
        >>> GenericDict(dict_).min_value(len)
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
        >>> from testing import dict_, dictitem
        >>> GenericDict(dict_).sort(sortby = 'key')
        OrderedDict([(1, '1111'), (2, '222'), (3, '4'), (4, '33')])
        >>> GenericDict(dictitem).sort(sortby = 'key')
        [([1], '1111'), ([2], '222'), ([3], '4'), ([4], '33')]
        >>> GenericDict(dict_).sort(sortby = 'value', keyfunc = len)
        OrderedDict([(3, '4'), (4, '33'), (2, '222'), (1, '1111')])
        >>> GenericDict(dictitem).sort(sortby = 'value', keyfunc = len)
        [([3], '4'), ([4], '33'), ([2], '222'), ([1], '1111')]
        """
        if sortby not in ['key', 'value']:
            raise ValueError(f"'{sortby}' not in ['key', 'value']")

        def keyfunc_(key_value):
            return keyfunc(key_value[sortby == 'value'])

        try:
            sorted_ = sorted(inst._gd.items(), key = keyfunc_)
        except AttributeError:
            return sorted(inst._gd, key = keyfunc_)
        else:
            return collections.OrderedDict(sorted_)
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
        >>> tuple = (11, 22, 33, 44)
        >>> def evenodd(x): return 'even' if even(x) else 'odd'
        >>> eq = Equivalence(tuple, evenodd)
        >>> MultiDict(eq.quotientset()).count()
        {'odd': 2, 'even': 2}
        """
        try:
            return {key: len(inst._multi[key]) for key in inst._multi}
        except ValueError:
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
    else:
        raise TypeError("Incorrect type for argument 'split' in partition(seq, split)")
#endregion

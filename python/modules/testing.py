##region IMPORTS ##
# imports aliased with "_" so they don't get tabcompleted
from __future__ import (
    division         as _division,
    print_function   as _print_function,
    unicode_literals as _unicode_literals)

import sys as _sys        ## VARIABLES
import random as _random  ## UTILITIES
#endregion

##region VARIABLES ##
isPython2 = _sys.version_info.major < 3
#endregion

##region SMALL FUNCTIONS ##
def ident(x):
    return x

def even(integer):
    return not(odd(integer))

def odd(integer):
    return bool(integer % 2)
#endregion

##region TESTING FUNCTIONS##
def dim(seq):
    dimension = []
    while isinstance(seq, (list, tuple)):
        dimension.append(len(seq))
        try:
            seq = seq[0]
        except IndexError:
            break
    return dimension

def hash_or_order(seq, keyfunc = ident):
    result = {}

    try:
        dict(zip(map(keyfunc, seq), seq))
    except TypeError:
        result['ishashable'] = False
    else:
        result['ishashable'] = True

    try:
        seq.sort(key = keyfunc)
    except TypeError:
        result['isorderable'] = False
    else:
        result['isorderable'] = True

    return result
#endregion

##region UTILITIES##
def randseq(start, end, count = None, repeat = False):
    """
    >>> _random.seed(0)
    >>>
    >>> if isPython2:
    ...     randseq(1, 10, repeat = False) == [9, 7, 4, 2, 8, 3, 6, 1, 5, 10]
    ...     randseq(1, 10, repeat = True)  == [10, 6, 3, 8, 7, 3, 10, 10, 9, 10]
    ... else:
    ...     randseq(1, 10, repeat = False) == [7, 10, 1, 3, 5, 4, 6, 2, 9, 8]
    ...     randseq(1, 10, repeat = True)  == [10, 4, 9, 3, 5, 3, 2, 10, 5, 9]
    True
    True
    """

    intlist = range(start, end + 1)

    if count is None:
        count = end - start + 1

    if repeat is False:
        return _random.sample(intlist, count)

    elif repeat is True:
        return [_random.choice(intlist) for counter in range(count)]
#endregion

##region TEST TYPES##
smalldict   = {1: '11', 2: '22', 4: '33', 3: '44'}

bigfile     = 'F:/Program Files/tools/cain/Wordlists/Wordlist.txt'

smalllist   = ['a', 'b', 'c', 'd', 'e']
biglist     = range(100)

smallstring = 'The quick brown fox jumps over the lazy dog'
bigstring   = open(bigfile).read()

smalltuple  = (11, 22, 33, 44)
bigtuple    = tuple(range(100))

table       = [['a1', 'b1', 'c1', 'd1', 'e1'],
               ['a2', 'b2', 'c2', 'd2', 'e2'],
               ['a3', 'b3', 'c3', 'd3', 'e3'],
               ['a4', 'b4', 'c4', 'd4', 'e4']]

dictitem    = [([1], '11'), ([2], '22'), ([4], '33'), ([3], '44')]
#endregion

##region HASH AND SORT##
hashable    = [11, '22', 33]

unhashable  = [11, [22], 33]

orderable   = [[11], [22], [33]]

unorderable = [11, ['22'], 33]
#endregion

##region REGRESSION TESTS ##
__test__ = {
    'hashable':    """
>>> hash_or_order(hashable)['ishashable']
True
                   """,

    'unhashable':  """
>>> hash_or_order(unhashable)['ishashable']
False
                   """,

    'orderable':   """
>>> hash_or_order(orderable)['isorderable']
True
                   """,

    'unorderable': """
>>> if isPython2:
...     hash_or_order(unorderable)['isorderable']  == True
... else:
...     hash_or_order(unorderable)['isorderable']  == False
True
                   """
}
#endregion

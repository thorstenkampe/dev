##region IMPORTS ##
from __future__ import (
    division         as _division,
    print_function   as _print_function,
    unicode_literals as _unicode_literals)

import random as _random  ## UTILITIES
#endregion

##region TESTING FUNCTIONS##
def _ident(x):
    return x

def dim(seq):
    dimension = []
    while isinstance(seq, (list, tuple)):
        dimension.append(len(seq))
        try:
            seq = seq[0]
        except IndexError:
            break
    return dimension

def baseclass(seq, keyfunc = _ident):
    return {'ishashable': ishashable(seq, keyfunc),
            'isorderable': isorderable(seq, keyfunc)}

def ishashable(seq, keyfunc = _ident):
    try:
        dict(zip(map(keyfunc, seq), range(len(seq))))
    except TypeError:
        return False
    else:
        return True

def isorderable(seq, keyfunc = _ident):
    try:
        seq.sort(key = keyfunc)
    except TypeError:
        return False
    else:
        return True
#endregion

##region UTILITIES##
def randseq(start, end, count = None, repeat = False):
    """
    >>> _random.seed(0)
    >>> randseq(1, 10, repeat = False)
    [7, 10, 1, 3, 5, 4, 6, 2, 9, 8]
    >>> randseq(1, 10, repeat = True)
    [10, 4, 9, 3, 5, 3, 2, 10, 5, 9]
    """

    intlist = range(start, end + 1)

    if count is None:
        count = end - start + 1

    if repeat is False:
        return _random.sample(intlist, count)

    elif repeat is True:
        return [_random.choice(intlist) for counter in range(count)]

def rows(table):
    try:
        for lineno, row in enumerate(table):
            print('%*s:' % (len(str(len(table))), lineno + 1), row)
    except TypeError:
        print(table)
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

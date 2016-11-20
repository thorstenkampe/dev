##region IMPORTS ##
from __future__ import division, print_function, unicode_literals

import toolbox                                          # TESTING FUNCTIONS
import functools, gc, operator, random, time, toolbox   # UTILITIES
import random
from pprint import pprint; from pycompat import python  # REGRESSION TESTS
#endregion

try:
    FileNotFoundError
except NameError:
    FileNotFoundError = IOError  # `FileNotFoundError` is Python3

##region TESTING FUNCTIONS ##
def _ishashable(seq, keyfunc = toolbox.ident):
    try:
        dict(zip(map(keyfunc, seq), seq))
    except TypeError:
        return False
    else:
        return True

def _isorderable(seq, keyfunc = toolbox.ident):
    try:
        seq.sort(key = keyfunc)
    except TypeError:
        return False
    else:
        return True
#
def hash_or_order(seq, keyfunc = toolbox.ident):
    return {'ishashable':  _ishashable(seq, keyfunc),
            'isorderable': _isorderable(seq, keyfunc)}
#endregion

##region UTILITIES ##
def explore(obj):
    methods   = []
    variables = {}

    for attribute in dir(obj):
        if not attribute.startswith('_'):
            try:
                variables[attribute] = vars(obj)[attribute]
            except KeyError:
                methods.append(attribute)

    return {'VARS': variables, 'METHODS': methods}

def makedimlist(seq):
    dimlist = list(range(functools.reduce(operator.mul, seq)))
    for dim in reversed(seq[1:]):
        dimlist = toolbox.partition(dimlist, dim)
    return dimlist

def randseq(start, end, count = None, repeat = False):
    intlist = range(start, end + 1)

    if count is None:
        count = end - start + 1

    if repeat is False:
        return random.sample(intlist, count)

    elif repeat is True:
        return [random.choice(intlist) for counter in range(count)]

def timer(iteration, *func_and_args):
    """
    print the time elapsed (in seconds) evaluating function iteration
    times (default is '1')
    """
    if isinstance(iteration, int):
        function, args = func_and_args[0], func_and_args[1:]
    else:
        # if first argument is not a number, set function to iteration
        # and iteration to '1'
        iteration, function, args = 1, iteration, func_and_args

    iteration = range(iteration)
    gc.collect()  # force garbage collection
    start_time_cpu   = time.clock()
    start_time_total = time.time()

    for index in iteration:
        function(*args)

    print('cpu: %.3f' % (time.clock() - start_time_cpu),
          'total: %.3f' % (time.time() - start_time_total))
#endregion

##region TEST TYPES ##
smallstring = 'The quick brown fox jumps over the lazy dog'
_bigfile1   = 'F:/cygwin/home/thorsten/python/modules/Wordlist.txt'
_bigfile2   = '/home/thorsten/python/modules/Wordlist.txt'
try:
    bigfile = open(_bigfile1)
except FileNotFoundError:
    bigfile = open(_bigfile2)

smalllist   = ['a', 'b', 'c', 'd', 'e']
biglist     = range(100)

smalltuple  = (11, 22, 33, 44)
bigtuple    = tuple(range(100))

smalldict   = {1: '11', 2: '22', 4: '33', 3: '44'}
dictitem    = [([1], '11'), ([2], '22'), ([4], '33'), ([3], '44')]

table       = [('a1', 'b1', 'c1', 'd1', 'e1'),
               ('a2', 'b2', 'c2', 'd2', 'e2'),
               ('a3', 'b3', 'c3', 'd3', 'e3'),
               ('a4', 'b4', 'c4', 'd4', 'e4')]

dimlist     = [(['01', '02', '03', '04'],
                ['05', '06', '07', '08'],
                ['09', '10', '11', '12']),
               (['13', '14', '15', '16'],
                ['17', '18', '19', '20'],
                ['21', '22', '23', '24'])]

_testtypes = '''\
smallstring: 'The quick brown fox jumps over the lazy dog'
bigfile:      <word list of 300,000 words> (use `bigfile.read()` to read)

smalllist:   ['a', 'b', 'c', 'd', 'e']
biglist:     [0, 1, ... , 98, 99]

smalltuple:  (11, 22, 33, 44)
bigtuple:    (0, 1, ... , 98, 99)

smalldict:   {{1: '11', 2: '22', 4: '33', 3: '44'}}
dictitem:    [([1], '11'), ([2], '22'), ([4], '33'), ([3], '44')]

table:       [('a1', 'b1', 'c1', 'd1', 'e1'),
              ('a2', 'b2', 'c2', 'd2', 'e2'),
              ('a3', 'b3', 'c3', 'd3', 'e3'),
              ('a4', 'b4', 'c4', 'd4', 'e4')]

dimlist:     [(['01', '02', '03', '04'],
               ['05', '06', '07', '08'],
               ['09', '10', '11', '12']),
              (['13', '14', '15', '16'],
               ['17', '18', '19', '20'],
               ['21', '22', '23', '24'])]'''

def testtypes():
    print(_testtypes)

#
hashable    = [11, '22', 33]
unhashable  = [11, [22], 33]
orderable   = [[11], [22], [33]]
unorderable = [11, ['22'], 33]
#endregion

##region REGRESSION TESTS ##
__test__ = {
    'hash_or_order': """
>>> if   python.is2xx:
...     hash_or_order(hashable)    == {'ishashable': True,  'isorderable': True}
...     hash_or_order(unhashable)  == {'ishashable': False, 'isorderable': True}
...     hash_or_order(unorderable) == {'ishashable': False, 'isorderable': True}
... elif python.is3xx:
...     hash_or_order(hashable)    == {'ishashable': True,  'isorderable': False}
...     hash_or_order(unhashable)  == {'ishashable': False, 'isorderable': False}
...     hash_or_order(unorderable) == {'ishashable': False, 'isorderable': False}
True
True
True

>>> pprint(hash_or_order(orderable))
{'ishashable': False, 'isorderable': True}
                     """,

    'makedimlist':   """
>>> makedimlist([2, 3, 4])  # doctest: +ELLIPSIS
[[[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11]], [[..., [20, 21, 22, 23]]]
                     """,

    'randseq':       """
>>> random.seed(0)
>>> if   python.is2xx:
...     randseq(1, 10, repeat = False) == [9, 7, 4, 2, 8, 3, 6, 1, 5, 10]
...     randseq(1, 10, repeat = True)  == [10, 6, 3, 8, 7, 3, 10, 10, 9, 10]
... elif python.is3xx:
...     randseq(1, 10, repeat = False) == [7, 10, 1, 3, 5, 4, 6, 2, 9, 8]
...     randseq(1, 10, repeat = True)  == [10, 4, 9, 3, 5, 3, 2, 10, 5, 9]
True
True
                     """
}
#endregion

from __future__ import (division as _division,
                        print_function as _print_function,
                        unicode_literals as _unicode_literals)
import random as _random, gc as _gc, time as _time,\
       toolbox as _toolbox

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

def even(integer):
    return not(odd(integer))

def odd(integer):
    return bool(integer % 2)

def baseclass(seq, keyfunc = _toolbox.ident):
    return {'ishashable': ishashable(seq, keyfunc),
            'isorderable': isorderable(seq, keyfunc)}

def ishashable(seq, keyfunc = _toolbox.ident):
    try:
        dict(zip(map(keyfunc, seq), range(len(seq))))
    except TypeError:
        return False
    else:
        return True

def isorderable(seq, keyfunc = _toolbox.ident):
    try:
        seq.sort(key = keyfunc)
    except TypeError:
        return False
    else:
        return True
#endregion

##region UTILITIES##
def randseq(start, end, count = None, repeat = False):
    if count is None:
        count = end - start + 1

    if repeat is False:
        return _random.sample(range(start, end + 1), count)

    elif repeat is True:
        return [_random.randint(start, end) for counter in range(count)]

def rows(table):
    try:
        for lineno, row in enumerate(table):
            print('%*s:' % (len(str(len(table))), lineno + 1), row)
    except TypeError:
        print(table)

def timer(iteration, *func_and_args):
    """
    print the time elapsed (in seconds) evaluating function iteration
    times (default is '1')
    """
    if isinstance(iteration, int):
        function, args = func_and_args[0], func_and_args[1:]
    else:
        # if first argument is not a number, set function to iteration and
        # iteration to '1'
        iteration, function, args = 1, iteration, func_and_args

    iteration        = range(iteration)
    _gc.collect()  # force garbage collection
    start_time_cpu   = _time.clock()
    start_time_total = _time.time()

    for index in iteration:
        function(*args)

    print('cpu: %.3f'   % (_time.clock() - start_time_cpu),
          'total: %.3f' % (_time.time()  - start_time_total))
#endregion

##region TEST TYPES##
smalldict    = {1: '11', 2: '22', 4: '33', 3: '44'}

bigfile      = 'F:/Program Files/tools/cain/Wordlists/Wordlist.txt'

smalllist    = ['a', 'b', 'c', 'd', 'e']
biglist      = range(100)

smallstring  = 'The quick brown fox jumps over the lazy dog'
bigstring    = open(bigfile).read()

smalltuple   = (11, 22, 33, 44)
bigtuple     = tuple(range(100))

table        = [['a1', 'b1', 'c1', 'd1', 'e1'],
                ['a2', 'b2', 'c2', 'd2', 'e2'],
                ['a3', 'b3', 'c3', 'd3', 'e3'],
                ['a4', 'b4', 'c4', 'd4', 'e4']]

dictitem     = [([1], '11'), ([2], '22'), ([4], '33'), ([3], '44')]
#endregion

##region HASH AND SORT##
hashable     = [11, '22', 33]

nonhashable  = [11, [22], 33]

orderable    = [[11], [22], [33]]

nonorderable = [11, ['22'], 33]
#endregion

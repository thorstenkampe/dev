##region TESTING FUNCTIONS ##
import toolbox

def _ishashable(seq, keyfunc = toolbox.ident):
    """
    >>> _ishashable(hashable)
    True
    >>> _ishashable(unhashable)
    False
    """
    try:
        dict(zip(map(keyfunc, seq), seq))
    except TypeError:
        return False
    else:
        return True

def _isorderable(seq, keyfunc = toolbox.ident):
    """
    >>> _isorderable(orderable)
    True
    >>> _isorderable(unorderable)
    False
    """
    try:
        seq.sort(key = keyfunc)
    except TypeError:
        return False
    else:
        return True

def hash_or_order(seq, keyfunc = toolbox.ident):
    return {'ishashable':  _ishashable(seq, keyfunc),
            'isorderable': _isorderable(seq, keyfunc)}
#endregion

##region UTILITIES ##
import functools, gc, operator, random, time, toolbox

def explore(obj):
    methods   = []
    variables = {}

    for attribute in dir(obj):
        if not attribute.startswith('_'):
            try:
                variables[attribute] = vars(obj)[attribute]
            except KeyError:
                methods.append(attribute)
            except TypeError:
                pass
    return {'VARS': variables, 'METHODS': methods}

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
    start_time_total = time.time()

    for index in iteration:
        function(*args)

    print('total: %.3f' % (time.time() - start_time_total))
#endregion

##region TEST TYPES ##
string_     = 'The quick brown fox jumps over the lazy dog'

list_       = ['aaaaa', 'bbbb', 'ccc', 'dd', 'e']

tuple_      = (11, 22, 33, 44, 55, 66, 77, 88, 99)

dict_       = {1: '1111', 2: '222', 4: '33', 3: '4'}
dictitem    = [([1], '1111'), ([2], '222'), ([4], '33'), ([3], '4')]

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

hashable    = [11, '22', 33]
unhashable  = [11, [22], 33]

orderable   = [[11], [22], [33]]
unorderable = [11, ['22'], 33]

def testtypes():
    print(f"""\
string_:     '{string_}'

list_:       {list_}

tuple_:      {tuple_}

dict_:       {dict_}
dictitem:    {dictitem}

table:       [('a1', 'b1', 'c1', 'd1', 'e1'),
              ('a2', 'b2', 'c2', 'd2', 'e2'),
              ('a3', 'b3', 'c3', 'd3', 'e3'),
              ('a4', 'b4', 'c4', 'd4', 'e4')]

dimlist:     [(['01', '02', '03', '04'],
               ['05', '06', '07', '08'],
               ['09', '10', '11', '12']),
              (['13', '14', '15', '16'],
               ['17', '18', '19', '20'],
               ['21', '22', '23', '24'])]

hashable:    {hashable}
unhashable:  {unhashable}

orderable:   {orderable}
unorderable: {unorderable}
""")
#endregion

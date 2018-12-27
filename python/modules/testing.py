##region TESTING FUNCTIONS ##
import toolbox

def ishashable(seq, keyfunc = toolbox.ident):
    """
    >>> ishashable(hashable)
    True
    >>> ishashable(unhashable)
    False
    """
    try:
        dict(zip(map(keyfunc, seq), seq))
    except TypeError:
        return False
    else:
        return True

def isorderable(seq, keyfunc = toolbox.ident):
    """
    >>> isorderable(orderable)
    True
    >>> isorderable(unorderable)
    False
    """
    try:
        seq.sort(key = keyfunc)
    except TypeError:
        return False
    else:
        return True
#endregion

##region UTILITIES ##
import gc, time, toolbox

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
    print the time elapsed (in seconds) evaluating function iteration times
    (default is '1')
    """
    if isinstance(iteration, int):
        function, args = func_and_args[0], func_and_args[1:]
    else:
        # if first argument is not a number, set function to iteration and 
        # iteration to '1'
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

hashable    = [11, '22', 33]
unhashable  = [11, [22], 33]

orderable   = [[11], [22], [33]]
unorderable = [11, ['22'], 33]
#endregion

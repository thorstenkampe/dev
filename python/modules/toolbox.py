# FUNCTIONS #
import collections, itertools, socket, urllib

def ident(x):
    return x

def even(integer):
    return not odd(integer)

def odd(integer):
    return bool(integer % 2)

def dim(seq):
    """
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

def equivalence(seq, keyfunc = ident):
    """
    partition seq into equivalence classes
    see http://en.wikipedia.org/wiki/Equivalence_relation
    >>> equivalence([1, 2, 3, 4], even)
    {False: [1, 3], True: [2, 4]}
    """
    eq = {}
    for obj in seq:
        eq.setdefault(keyfunc(obj), []).append(obj)
    return eq

def flatten(seq):
    """
    >>> flatten(table)  # doctest: +ELLIPSIS
    ['a1', 'b1', 'c1', 'd1', 'e1', 'a2', ..., 'a4', 'b4', 'c4', 'd4', 'e4']
    """
    for dimension in dim(seq)[1:]:  # pylint: disable = unused-variable
        seq = itertools.chain.from_iterable(seq)
    return list(seq)

def periodic(counter, counter_at_sop, sop, eop):
    """
    wrap counter in range(sop, eop + 1)
    sop = start of period; eop = end of period
    """
    return (counter - counter_at_sop) % (eop - sop + 1) + sop

def dictsort(dict_, sortby, keyfunc=ident):
    """
    sort by key or value
    >>> dictsort(dict_, sortby='key')
    OrderedDict([(1, '1111'), (2, '222'), (3, '4'), (4, '33')])
    >>> dictsort(dict_, sortby='value', keyfunc=len)
    OrderedDict([(3, '4'), (4, '33'), (2, '222'), (1, '1111')])
    """
    if sortby not in ['key', 'value']:
        raise ValueError(f"'{sortby}' not in ['key', 'value']")

    def keyfunc_(key_value):
        return keyfunc(key_value[sortby=='value'])

    return collections.OrderedDict(sorted(dict_.items(), key=keyfunc_))

def count(dict_):
    """returns the count of a dictionary with multiple values
    >>> count({'odd': [11, 33], 'even': [22, 44]})
    {'odd': 2, 'even': 2}
    """
    return {key: len(dict_[key]) for key in dict_}

# doesn't work through SSH tunnel
def port_reachable(host, port=None):
    if not port:
        url_components = urllib.parse.urlparse(host)
        host = url_components.hostname
        port = url_components.port

    with socket.socket() as sock:
        sock.settimeout(0.048)
        try:
            sock.connect((host, port))
        except (socket.timeout, socket.gaierror):
            return False
        else:
            return True

# PARTITION #
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
        for slice_ in split:
            part.append(seq[:slice_])
            seq = seq[slice_:]

        if seq:
            part += [seq]

        return part

    elif isinstance(split[0], str):
        for separator in split[1:]:
            seq = seq.replace(separator, split[0])
        return seq.split(split[0])
    else:
        raise TypeError("Incorrect type for argument 'split' in partition(seq, split)")

# TEST FUNCTIONS #
import gc, time

def ishashable(seq, keyfunc = ident):
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

def isorderable(seq, keyfunc=ident):
    """
    >>> isorderable(orderable)
    True
    >>> isorderable(unorderable)
    False
    """
    try:
        seq.sort(key=keyfunc)
    except TypeError:
        return False
    else:
        return True

#
def explore(obj):
    methods   = []
    variables = {}

    for attribute in dir(obj):
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

    for index in iteration:  # pylint: disable = unused-variable
        function(*args)

    print('total: %.3f' % (time.time() - start_time_total))

# TEST TYPES #
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

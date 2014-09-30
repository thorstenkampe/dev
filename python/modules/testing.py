import random, gc, time

#
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
    return not(integer % 2)

def ishashable(seq):
    try:
        dict(zip(seq, range(len(seq))))
    except TypeError:
        return False
    else:
        return True

def isorderable(seq):
    try:
        seq.sort()
    except TypeError:
        return False
    else:
        return True

def odd(integer):
    return bool(integer % 2)

#
def randseq(start, end, count = None, repeat = False):
    if count == None:
        count = end - start + 1

    if repeat == False:
        return random.sample(range(start, end + 1), count)

    elif repeat == True:
        return [random.randint(start, end) for counter in range(count)]

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
    gc.collect()  # force garbage collection
    start_time_cpu   = time.clock()
    start_time_total = time.time()

    for index in iteration:
        function(*args)

    print('cpu: %.3f'   % (time.clock() - start_time_cpu),
          'total: %.3f' % (time.time()  - start_time_total))

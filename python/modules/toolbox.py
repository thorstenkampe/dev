# coding: utf-8
from __future__ import division, print_function, unicode_literals
import collections, itertools, math, operator, string

##region##
def base(digitstr, oldbase, newbase):
    digits       = string.digits + string.ascii_uppercase
    newdigits    = ''
    numberbase10 = int(digitstr, oldbase)

    while numberbase10:
        numberbase10, lastdigit = divmod(numberbase10, newbase)
        newdigits = digits[lastdigit] + newdigits
    return max(newdigits, '0')

def ident(x):
    return x

def periodic(counter, counter_at_sop, sop, eop):
    """
    wrap counter in range(sop, eop + 1)
    sop = start of period; eop = end of period
    """
    return (counter - counter_at_sop) % (eop - sop + 1) + sop

def comb(n, k):
    return math.factorial(n) // (math.factorial(k) * math.factorial(n - k))

def perm(n, k):
    return math.factorial(n) // math.factorial(n - k)
#endregion

##region##
def combination (seq_or_n, k, repeat = False):
    # combinations are unordered
    if repeat is False:
        try:
            return itertools.combinations(seq_or_n, k)
        except TypeError:
            return comb(seq_or_n, k)

    elif repeat is True:
        try:
            return itertools.combinations_with_replacement(seq_or_n, k)
        except TypeError:
            return comb(seq_or_n + k - 1, k)

def permutation(seq_or_n, k, repeat = False):
    # permutations are ordered
    # k-permutations are sometimes called variations and then only
    # "full" n-permutations without replacement are called permutations
    # http://de.wikipedia.org/wiki/Abzählende_Kombinatorik#Begriffsabgrenzungen
    if repeat is False:
        try:
            return itertools.permutations(seq_or_n, k)
        except TypeError:
            return perm(seq_or_n, k)

    elif repeat is True:
        try:
            return itertools.product(seq_or_n, repeat = k)
        except TypeError:
            return seq_or_n ** k
#endregion

##region SET OPERATIONS ON MULTISETS ##
def union(seq1, seq2):
    return (collections.Counter(seq1) | collections.Counter(seq2)).elements()

def intersection(seq1, seq2):
    return (collections.Counter(seq1) & collections.Counter(seq2)).elements()

def difference(seq1, seq2):
    return (collections.Counter(seq1) - collections.Counter(seq2)).elements()

def symmetric_difference(seq1, seq2):
    seq1 = collections.Counter(seq1)
    seq2 = collections.Counter(seq2)
    return ((seq1 | seq2) - (seq1 & seq2)).elements()
#endregion

##region##
class QuotientSet(object):
    """
    partition seq into equivalence classes
    see http://en.wikipedia.org/wiki/Equivalence_relation

    What are the most common word lengths in word list of 310,000 words?
    >>> qs = QuotientSet(bigstring.splitlines(), len)
    >>> dictsort(qs.counter(), sortby = 'value')
    [... (8, 43555), (10, 46919), (9, 48228)]
    """

    def __init__(inst, seq, keyfunc = ident):
        inst._seq       = seq
        inst._canonproj = keyfunc
        try:
            inst._qs = inst._qshashable()
        except TypeError:
            try:
                inst._qs = inst._qsorderable()
            except TypeError:
                inst._qs = inst._qsunorderable()

    def _qshashable(inst):
        qs = collections.defaultdict(list)
        for obj in inst._seq:
            qs[inst._canonproj(obj)].append(obj)
        return dict(qs)

    def _qsorderable(inst):
        return [(proj_value, list(equiv_class))
                for proj_value, equiv_class in
                itertools.groupby(sorted(inst._seq, key = inst._canonproj), inst._canonproj)]

    def _qsunorderable(inst):
        qs          = []
        proj_values = []

        for obj in inst._seq:
            proj_value = inst._canonproj(obj)
            try:
                qs[proj_values.index(proj_value)].append(obj)
            except ValueError:
                qs.append([obj])
                proj_values.append(proj_value)
        return list(zip(proj_values, qs))

    def _extr(inst, min_or_max):
        extremum = min_or_max(inst._qs)
        if isinstance(inst._qs, dict):  # _qs hashable
            return {extremum: inst._qs[extremum]}
        else:                           # _qs not hashable
            return [extremum]

    def counter(inst):
        if isinstance(inst._qs, dict):
            counter = {}
            for proj_value in inst._qs:
                counter[proj_value] = len(inst._qs[proj_value])
            return counter
        else:
            return [(proj_value, len(equiv_class))
                    for proj_value, equiv_class in inst._qs]

    def equivalenceclass(inst, key):
        if isinstance(inst._qs, dict):
            return inst._qs[key]
        else:
            return inst._qs[list(zip(*inst._qs))[0].index(key)][1]

    def max(inst):
        return inst._extr(max)

    def min(inst):
        return inst._extr(min)

    def partition(inst):
        if isinstance(inst._qs, dict):
            return inst._qs.values()
        else:
            return list(zip(*inst._qs))[1]

    def quotientset(inst):
        return inst._qs
#endregion

##region##
def cartes(seq0, seq1):
    """ return the Cartesian Product of two sequences """
    # "single column" sequences have to be specified as [item] or (item,) - not (item)
    return [item0 + item1 for item0 in seq0 for item1 in seq1]

def dictsort(adict, sortby):
    """ sort dictionary by key or value """
    return collections.OrderedDict(
        sorted(adict.items(), key = operator.itemgetter(sortby == 'value')))

def makeset(seq):
    """ make seq a true set by removing duplicates """
    try:
        return set(seq)
    except TypeError:  # seq has unhashable elements
        return [part[0] for part in QuotientSet(seq).partition()]

def partition(seq, split):
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
#endregion

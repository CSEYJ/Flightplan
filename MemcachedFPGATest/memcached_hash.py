import sys
from collections import defaultdict
from pprint import pprint
import os
import random
sys.path.append(os.path.realpath(os.path.dirname(__file__) + "/../FPGA/MemcachedVivadoHLS/"))
from MemHLS_hash_py import str_hash

def gen_hashes(n, max=100000):
    order = list(range(max))
    random.shuffle(order)
    for k in order:
        n-=1
        if n < 0:
            break
        str_k = "{:08d}".format(k)
        yield str_k, str_hash(str_k)

def gen_mostly_collisions(n, max=10000000):
    keys_so_far = set()
    hashes_so_far = set()
    for _ in range(max):
        k = random.randint(1, max)
        while k in keys_so_far:
            k = random.randint(1, max)
        keys_so_far.add(k)
        str_k = "{:08d}".format(k)
        h = str_hash(str_k)
        if h in hashes_so_far or random.random() < .05:
            yield str_k, h
            n -= 1
            if n < 0:
                break


def gen_collisions(keys, n, max=100000):
    h = str(str_hash(k) for k in keys)
    l = []
    for i in range(max):
        n-=1
        if n < 0:
            break
        sti = "{:08d}".format(i)
        if str_hash(sti) == h:
            yield sti, str_hash(sti)

def gen_no_collisions(n):
    hashes = set()
    i = 0
    while len(hashes) < 1000:
        n-=1
        if n < 0:
            break
        sti = "{:08d}".format(i)
        h = str_hash(sti)
        if h not in hashes:
            hashes.add(h)
            yield sti, h
        i+=1

def get_collisions(key, max=10000):
    h = str_hash(key)
    l = []
    for i in range(max):
        sti = "{:08d}".format(i)
        if str_hash(sti) == h:
            l.append(sti)
    return l

def get_all_collisions(max=10000):
    hash_out = defaultdict(list)
    for i in range(max):
        hash_out[str_hash(str(i))].append(str(i))
    return dict(hash_out)

if __name__  == '__main__':
    if len(sys.argv) == 1:
        hash_out = get_all_collisions()
        sorted_out = sorted(hash_out.items(), key=lambda x:len(x[1]))
        for o in sorted_out[:10]:
            print("{}: {}".format(o[0], o[1]))

        for o in sorted_out[-10:]:
            print("{}: {}".format(o[0], o[1]))
    else:
        pprint(get_collisions(sys.argv[1]))

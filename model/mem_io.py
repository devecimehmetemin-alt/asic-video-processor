## shared helpers for reading .mem (hex, one value per line) and the .meta sidecar.
## imported by mem_to_png.py, compare.py, and the per-stage models.
import numpy as np


def load_mem(path, h=None, w=None):
    vals = []
    with open(path) as f:
        for line in f:
            line = line.split("//")[0].strip()   # drop // comments + whitespace
            if line:
                vals.append(int(line, 16))        # hex -> int
    arr = np.array(vals, dtype=np.uint8)
    if h is not None and w is not None:
        arr = arr.reshape(h, w)
    return arr


def load_meta(path="array_data.meta"):
    with open(path) as f:
        h, w = map(int, f.read().split())         # H W
    return h, w

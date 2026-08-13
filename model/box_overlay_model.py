import numpy as np
from mem_io import load_mem
from pathlib import Path

HERE = Path(__file__).parent

W, H = 676, 450
MIN_X, MAX_X = 176, 662
MIN_Y, MAX_Y = 42, 350

pixels = load_mem(HERE / "rtl_out_gamma.mem")

out = pixels.copy()

i = 0
for y in range(H):
    for x in range(W):
        top_bottom = MIN_X <= x <= MAX_X and (y == MIN_Y or y == MAX_Y)
        left_right = MIN_Y <= y <= MAX_Y and (x == MIN_X or x == MAX_X)
        if top_bottom or left_right:
            out[i] = 0
            out[i + 1] = 255
            out[i + 2] = 0
        i += 3

np.savetxt(HERE / "overlay_ref.mem", out, fmt="%02x")
print(f"wrote overlay_ref.mem ({W}x{H})")

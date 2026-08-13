import numpy as np
from mem_io import load_mem, load_meta
from pathlib import Path

HERE = Path(__file__).parent
V_MIN = 40

h, w = 450, 676
pixels = load_mem(HERE / "rtl_out_gamma.mem")   # flat R,G,B,R,G,B ...

mask = []
min_x, max_x, min_y, max_y = w, 0, h, 0
saw = 0

i = 0
for y in range(h):
    for x in range(w):
        r = int(pixels[i])
        g = int(pixels[i + 1])
        b = int(pixels[i + 2])
        i += 3

        cmax = max(r, g, b)
        cmin = min(r, g, b)
        delta = cmax - cmin
        br_abs = b - r if b >= r else r - b

        green = (g >= r and g >= b) and (cmax >= V_MIN) \
            and (2 * delta >= cmax) and (2 * br_abs <= delta)

        if green:
            mask.append(1)
            saw = 1
            if x < min_x: min_x = x
            if x > max_x: max_x = x
            if y < min_y: min_y = y
            if y > max_y: max_y = y
        else:
            mask.append(0)

np.savetxt(HERE / "match_ref.mem", np.array(mask, dtype=np.uint8), fmt="%02x")
print("green pixels:", sum(mask))
print(f"box: min_x={min_x} max_x={max_x} min_y={min_y} max_y={max_y} valid={saw}")

import numpy as np
from pathlib import Path
from mem_io import load_mem, load_meta
from black_level_model import subtract_offset
from white_balance_model import white_balance_model
from debayer_model import demosaic_rggb, interior_stream

HERE = Path(__file__).parent
V_MIN = 40

h, w = load_meta(HERE / "array_data.meta")
raw = load_mem(HERE / "array_data.mem", h, w)
print(f"raw {w}x{h}")

bl = subtract_offset(raw, [5, 10, 15]).reshape(h, w)
print("black_level done")

wb = white_balance_model(bl, [1.4, 1, 2]).reshape(h, w)
print("white_balance done")

rgb = demosaic_rggb(wb)
stream = interior_stream(rgb)
print("debayer done")

lut = [round((i / 255.0) ** (1.0 / 2.2) * 255.0) for i in range(256)]
g = np.array([lut[p] for p in stream], dtype=np.uint8)
print("gamma done")

np.savetxt(HERE / "pipeline_spine_ref.mem", g, fmt="%02x")
print(f"wrote pipeline_spine_ref.mem ({g.size} bytes, no box)")

IW, IH = w - 2, h - 2

min_x, max_x, min_y, max_y = IW, 0, IH, 0
saw = 0
i = 0
for y in range(IH):
    for x in range(IW):
        r = int(g[i])
        gg = int(g[i + 1])
        b = int(g[i + 2])
        i += 3
        cmax = max(r, gg, b)
        cmin = min(r, gg, b)
        delta = cmax - cmin
        br_abs = b - r if b >= r else r - b
        if (gg >= r and gg >= b) and cmax >= V_MIN \
                and (2 * delta >= cmax) and (2 * br_abs <= delta):
            saw = 1
            if x < min_x: min_x = x
            if x > max_x: max_x = x
            if y < min_y: min_y = y
            if y > max_y: max_y = y

print(f"color_detect box: min_x={min_x} max_x={max_x} min_y={min_y} max_y={max_y} valid={saw}")

out = g.copy()
if saw:
    i = 0
    for y in range(IH):
        for x in range(IW):
            top_bottom = min_x <= x <= max_x and (y == min_y or y == max_y)
            left_right = min_y <= y <= max_y and (x == min_x or x == max_x)
            if top_bottom or left_right:
                out[i] = 0
                out[i + 1] = 255
                out[i + 2] = 0
            i += 3

np.savetxt(HERE / "pipeline_ref.mem", out, fmt="%02x")
print(f"wrote pipeline_ref.mem ({IW}x{IH}, {out.size} bytes)")

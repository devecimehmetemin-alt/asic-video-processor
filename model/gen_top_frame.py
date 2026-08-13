## Generates the tiny 16x16 golden pair for sim/tb_top.sv:
##   frame_in.mem  - Bayer sensor bytes the testbench streams in over UART
##   frame_ref.mem - the RGB output the full pipeline should produce
## Reuses the exact same stage models as pipeline_model.py, so a tb_top pass
## proves the whole rx_serial -> pipeline -> tx_serial chain matches the model.
import numpy as np
from pathlib import Path

from bayer_mosaic import mosaic_rggb
from black_level_model import subtract_offset
from white_balance_model import white_balance_model
from debayer_model import demosaic_rggb, interior_stream

HERE = Path(__file__).parent
W = H = 16
V_MIN = 40

# deterministic 16x16 RGB image with a green patch so color_detect fires
rng = np.random.default_rng(1234)
img = rng.integers(0, 256, size=(H, W, 3), dtype=np.uint8)
img[5:12, 5:12, 0] = 20    # R
img[5:12, 5:12, 1] = 200   # G
img[5:12, 5:12, 2] = 20    # B

raw = mosaic_rggb(img)                       # (H, W) Bayer, raster order
np.savetxt(HERE / "frame_in.mem", raw.flatten(), fmt="%02x")

# same pipeline as pipeline_model.py
bl = subtract_offset(raw, [5, 10, 15]).reshape(H, W)
wb = white_balance_model(bl, [1.4, 1, 2]).reshape(H, W)
rgb = demosaic_rggb(wb)
stream = interior_stream(rgb)

lut = [round((i / 255.0) ** (1.0 / 2.2) * 255.0) for i in range(256)]
g = np.array([lut[p] for p in stream], dtype=np.uint8)

IW, IH = W - 2, H - 2
min_x, max_x, min_y, max_y = IW, 0, IH, 0
saw = 0
i = 0
for y in range(IH):
    for x in range(IW):
        r, gg, b = int(g[i]), int(g[i + 1]), int(g[i + 2])
        i += 3
        cmax, cmin = max(r, gg, b), min(r, gg, b)
        delta = cmax - cmin
        br_abs = b - r if b >= r else r - b
        if (gg >= r and gg >= b) and cmax >= V_MIN \
                and (2 * delta >= cmax) and (2 * br_abs <= delta):
            saw = 1
            min_x, max_x = min(min_x, x), max(max_x, x)
            min_y, max_y = min(min_y, y), max(max_y, y)

print(f"box: min_x={min_x} max_x={max_x} min_y={min_y} max_y={max_y} valid={saw}")

out = g.copy()
if saw:
    i = 0
    for y in range(IH):
        for x in range(IW):
            tb = min_x <= x <= max_x and (y == min_y or y == max_y)
            lr = min_y <= y <= max_y and (x == min_x or x == max_x)
            if tb or lr:
                out[i], out[i + 1], out[i + 2] = 0, 255, 0
            i += 3

np.savetxt(HERE / "frame_ref.mem", out, fmt="%02x")
print(f"wrote frame_in.mem ({raw.size} bytes), frame_ref.mem ({out.size} bytes, {IW}x{IH}x3)")

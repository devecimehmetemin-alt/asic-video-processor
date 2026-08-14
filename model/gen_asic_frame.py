## Generates the 64x64 golden pair for sim/tb_isp_core.sv:
##   asic_in.mem  - Bayer sensor bytes the testbench streams in
##   asic_ref.mem - the RGB output isp_core should produce (interior only)
## isp_core stops at gamma, so there is no box overlay here - this is the
## ISP spine alone, at the reduced width the ASIC build targets.
import numpy as np
from pathlib import Path

from bayer_mosaic import mosaic_rggb
from black_level_model import subtract_offset
from white_balance_model import white_balance_model
from debayer_model import demosaic_rggb, interior_stream

HERE = Path(__file__).parent
W = H = 64

rng = np.random.default_rng(1234)
img = rng.integers(0, 256, size=(H, W, 3), dtype=np.uint8)
img[20:45, 20:45, 0] = 20
img[20:45, 20:45, 1] = 200
img[20:45, 20:45, 2] = 20

raw = mosaic_rggb(img)
np.savetxt(HERE / "asic_in.mem", raw.flatten(), fmt="%02x")

bl = subtract_offset(raw, [5, 10, 15]).reshape(H, W)
wb = white_balance_model(bl, [1.4, 1, 2]).reshape(H, W)
rgb = demosaic_rggb(wb)
stream = interior_stream(rgb)

lut = [round((i / 255.0) ** (1.0 / 2.2) * 255.0) for i in range(256)]
g = np.array([lut[p] for p in stream], dtype=np.uint8)

np.savetxt(HERE / "asic_ref.mem", g, fmt="%02x")
print(f"wrote asic_in.mem ({raw.size} bytes), "
      f"asic_ref.mem ({g.size} bytes, {W-2}x{H-2}x3)")

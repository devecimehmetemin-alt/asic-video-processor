## render an RGB .mem (3 interleaved bytes per pixel: R,G,B) back to a PNG.
## mem_to_png.py only handles single-channel (grayscale) .mem; debayer and the
## later color stages emit 3 bytes/pixel, so use this to eyeball those dumps.
##
## usage: python mem_to_png_rgb.py [mem] [png] [H W]
##   mem : input .mem (default debayer_ref.mem)
##   png : output image (default: <mem> with .png suffix)
##   H W : image dims. default = interior of array_data.meta (H-2, W-2), which
##         is what the debayer stream carries (1-px border dropped, mark-invalid).
import sys
import numpy as np
from PIL import Image
from pathlib import Path
from mem_io import load_mem, load_meta

HERE = Path(__file__).parent

mem_path = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / "debayer_ref.mem"
png_path = Path(sys.argv[2]) if len(sys.argv) > 2 else mem_path.with_suffix(".png")

if len(sys.argv) > 4:
    h, w = int(sys.argv[3]), int(sys.argv[4])
else:
    fh, fw = load_meta(HERE / "array_data.meta")    # full-frame dims
    h, w = fh - 2, fw - 2                           # interior only

flat = load_mem(mem_path)                           # flat uint8: R,G,B,R,G,B ...
expected = 3 * h * w
if flat.size != expected:
    sys.exit(f"size mismatch: {mem_path} has {flat.size} bytes, expected "
             f"{expected} (= 3 * {h} * {w}); pass explicit 'H W' for other dims.")

img = flat.reshape(h, w, 3)                          # (rows, cols, RGB)
Image.fromarray(img, "RGB").save(png_path)
print(f"wrote {png_path}  ({w}x{h} RGB, {h * w} px)")

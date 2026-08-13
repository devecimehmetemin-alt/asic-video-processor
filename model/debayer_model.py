## golden model for debayer.sv -- bilinear RGGB demosaic.
## reads a single-channel Bayer .mem, writes debayer_ref.mem: the interior RGB
## raster stream the RTL testbench dumps on valid_out (R,G,B per pixel).
##
## EDGE PROTOCOL (mark-invalid) -- must match the RTL exactly:
##   a 3x3 window has no neighbourhood at row 0, row H-1, col 0, col W-1, so
##   those border pixels are NOT demosaiced. They are treated as invalid and
##   emitted as black (0,0,0) in the full-frame view. The RTL enforces the same
##   by asserting valid_out only for interior centers (rows 1..H-2, cols 1..W-2),
##   so the border never appears in the .mem the testbench produces. debayer_ref.mem
##   therefore holds interior pixels only, in the same raster order.
##
## arithmetic matches the RTL bit-for-bit: neighbour sums use the same integer
## floor as the hardware shifts -- (a+b+c+d)>>2 and (a+b)>>1 -- so cast to a wide
## int before summing (as the RTL widens) and floor-shift, no rounding.
import numpy as np
from mem_io import load_mem, load_meta
from pathlib import Path


def demosaic_rggb(raw):
    ## raw: (H,W) uint8 Bayer (RGGB, R at (0,0)). returns (H,W,3) uint8 RGB,
    ## interior bilinear-interpolated, 1-px border left black (mark-invalid).
    h, w = raw.shape
    r = raw.astype(np.int32)                     # widen so 4*255 sums don't wrap
    out = np.zeros((h, w, 3), dtype=np.uint8)
    for i in range(1, h - 1):
        for j in range(1, w - 1):
            c = r[i, j]
            up, down, left, right = r[i - 1, j], r[i + 1, j], r[i, j - 1], r[i, j + 1]
            ul, ur, dl, dr = r[i - 1, j - 1], r[i - 1, j + 1], r[i + 1, j - 1], r[i + 1, j + 1]
            if i % 2 == 0 and j % 2 == 0:         # R site
                red   = c
                green = (up + down + left + right) >> 2
                blue  = (ul + ur + dl + dr) >> 2
            elif i % 2 == 1 and j % 2 == 1:       # B site
                red   = (ul + ur + dl + dr) >> 2
                green = (up + down + left + right) >> 2
                blue  = c
            elif i % 2 == 0 and j % 2 == 1:       # Gr -- green on a red row
                red   = (left + right) >> 1       # R neighbours horizontal
                green = c
                blue  = (up + down) >> 1          # B neighbours vertical
            else:                                 # Gb -- green on a blue row
                red   = (up + down) >> 1          # R neighbours vertical
                green = c
                blue  = (left + right) >> 1       # B neighbours horizontal
            out[i, j] = (red, green, blue)
    return out


def interior_stream(rgb):
    ## drop the 1-px black border and flatten to R,G,B,R,G,B... raster order,
    ## i.e. exactly what the RTL dumps: pix_out[0],[1],[2] per valid_out pixel,
    ## rows 1..H-2 outer, cols 1..W-2 inner.
    return rgb[1:-1, 1:-1, :].reshape(-1)


if __name__ == "__main__":
    HERE = Path(__file__).parent

    ## --- swatch phase test: an all-red frame must demosaic to a pure-red interior.
    ## catches any R/B phase swap instantly (a swap turns this all-blue).
    from bayer_mosaic import mosaic_rggb
    red = np.zeros((8, 8, 3), dtype=np.uint8)
    red[:, :, 0] = 255
    red_rgb = demosaic_rggb(mosaic_rggb(red))
    inner = red_rgb[1:-1, 1:-1]
    assert np.all(inner[:, :, 0] == 255), "R not full -> kernel/phase wrong"
    assert np.all(inner[:, :, 1] == 0),  "G leaked -> phase wrong"
    assert np.all(inner[:, :, 2] == 0),  "B leaked -> R/B swapped"
    print("swatch test PASS: all-red Bayer -> pure-red interior")

    ## --- reference from the real mosaic. debayer is a unit here, so feed the raw
    ## Bayer frame (array_data.mem). point this at white_balance_ref.mem instead
    ## to model the integrated spine (black_level -> white_balance -> debayer).
    h, w = load_meta(HERE / "array_data.meta")
    raw = load_mem(HERE / "array_data.mem", h, w)

    rgb = demosaic_rggb(raw)
    np.savetxt(HERE / "debayer_ref.mem", interior_stream(rgb), fmt="%02x")

    ## full-frame view (black border) to eyeball the hardware output
    from PIL import Image
    Image.fromarray(rgb).save(HERE / "debayer_out.png")

    n = (h - 2) * (w - 2)
    print(f"wrote debayer_ref.mem: {n} interior px x 3 = {n * 3} bytes; debayer_out.png {w}x{h}")

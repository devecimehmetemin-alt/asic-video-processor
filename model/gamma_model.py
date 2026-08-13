## golden model for gamma.sv -- gamma correction with a 256-entry lookup table.
## reads the debayer RGB stream, applies the same gamma 2.2 curve that gamma.sv
## bakes into GAMMA_LUT, and writes gamma_ref.mem to compare against
## rtl_out_gamma.mem.
##
## gamma is a point op: every byte (R, G and B the same) goes through the one
## table. no window, no border -- input length == output length.
import numpy as np
from mem_io import load_mem
from pathlib import Path

HERE = Path(__file__).parent

## build the curve: exactly the formula in gamma.sv's comment
##   out = round( (in/255) ** (1/2.2) * 255 )
lut = []
for i in range(256):
    out_val = round((i / 255.0) ** (1.0 / 2.2) * 255.0)
    lut.append(out_val)

## read the debayer output: flat R,G,B,R,G,B ... one byte per line
pixels = load_mem(HERE / "rtl_out_debayer.mem")

## push every byte through the table
out = []
for p in pixels:
    out.append(lut[p])

## write the reference stream, one hex byte per line
np.savetxt(HERE / "gamma_ref.mem", np.array(out, dtype=np.uint8), fmt="%02x")
print("wrote gamma_ref.mem:", len(out), "bytes")

## compares output from rtl to the output computed from python. each pixel should match for a pass.
## usage: python compare.py [rtl.mem] [ref.mem]   (defaults: rtl_out.mem, array_data.mem)
## exit code 0 = PASS, 1 = FAIL  (so it can be chained in scripts).
import sys
import numpy as np
from mem_io import load_mem

rtl_path = sys.argv[1] if len(sys.argv) > 1 else "rtl_out_pipeline2.mem"
ref_path = sys.argv[2] if len(sys.argv) > 2 else "pipeline_ref.mem"

rtl_out = load_mem(rtl_path)          # flat, no reshape yet
reference = load_mem(ref_path)        # flat

# check if same pixel count
if rtl_out.size != reference.size:
    print(f"FAIL: length mismatch — {rtl_path}={rtl_out.size}, {ref_path}={reference.size} "
          f"(diff {rtl_out.size - reference.size})")
    sys.exit(1)

if np.array_equal(rtl_out, reference):
    print(f"PASS: {rtl_out.size} pixels match ({rtl_path} == {ref_path})")
    sys.exit(0)

# pixel by pixel check failed: report how many differ and the first few.
diff = np.flatnonzero(rtl_out != reference)
print(f"FAIL: {diff.size} of {rtl_out.size} pixels differ")
for idx in diff[:10]:
    print(f"  pixel {int(idx)}: rtl={rtl_out[idx]}, ref={reference[idx]}")
sys.exit(1)

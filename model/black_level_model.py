import numpy as np
from mem_io import load_mem, load_meta
from pathlib import Path

def subtract_offset(raw, offset):
    row, col = raw.shape[0], raw.shape[1]
    arr_offsetted = np.zeros((row, col), dtype=np.uint8)
    for i in range(row):
        for j in range(col):
            if i % 2 == 0 and j % 2 == 0:
                val = int(raw[i, j]) - offset[0]  # red
                arr_offsetted[i, j] = max(0,val)
            elif i % 2 == 1 and j % 2 == 1:
                val = int(raw[i, j]) - offset[2] # blue
                arr_offsetted[i,j] = max(0,val)
            else:
                val = int(raw[i, j]) - offset[1]   # green
                arr_offsetted[i, j] = max(val,0)       

    arr_offsetted = arr_offsetted.flatten()
    return arr_offsetted

if __name__ == "__main__":
    HERE = Path(__file__).parent

    h, w = load_meta(HERE / "array_data.meta")
    raw_data = load_mem(HERE / "array_data.mem", h, w)

    bayer = subtract_offset(raw_data, offset = [5,10,15]) ##5,10,15 is used as output from optical black pixels
    np.savetxt(HERE / "black_level_ref.mem", bayer, fmt="%02x")


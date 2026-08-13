import numpy as np
from mem_io import load_mem, load_meta
from pathlib import Path

def white_balance_model(image_arr, gains):
    row, col = image_arr.shape[0], image_arr.shape[1]
    arr_balanced = np.zeros((row, col), dtype=np.uint8)
    gains_q28 = [round(g * 256) for g in gains]   # (1.4, 1.0, 2.0) -> [358, 256, 512]

    for i in range(row):
        for j in range(col):
            if i % 2 == 0 and j % 2 == 0:               # red
                val = apply_gain(int(image_arr[i,j]), gains_q28[0]) 
                arr_balanced[i, j] = val
            elif i % 2 == 1 and j % 2 == 1:             # blue
                val = apply_gain(int(image_arr[i,j]), gains_q28[2])   
                arr_balanced[i, j] = val
            else:                                       # green
                val = apply_gain(int(image_arr[i,j]), gains_q28[1]) 
                arr_balanced[i, j] = val      

    arr_balanced = arr_balanced.flatten()
    return arr_balanced

def apply_gain(pix: int, gain_q28: int) -> int:
    #Fixed-point white-balance multiply: Q2.8 gain, truncating shift, clamp to 255.

    product = pix * gain_q28      
    result = product >> 8         
    return min(result, 255)      # saturate at max possible value
            

if __name__ == "__main__":
    #tests for fixed point multiply
    assert apply_gain(200, 256) == 200   
    assert apply_gain(127, 512) == 254  
    assert apply_gain(128, 512) == 255   
    assert apply_gain(183, 358) == 255   
    assert apply_gain(184, 358) == 255   

    HERE = Path(__file__).parent

    h, w = load_meta(HERE / "array_data.meta")
    in_data = load_mem(HERE / "black_level_ref.mem", h, w)

    white_balanced = white_balance_model(in_data, gains = [1.4, 1, 2]) #effective gains for rgb levels.
    np.savetxt(HERE / "white_balance_ref.mem", white_balanced, fmt="%02x")
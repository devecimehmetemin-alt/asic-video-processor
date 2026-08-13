import numpy as np
from PIL import Image
from pathlib import Path
from bayer_mosaic import mosaic_rggb

HERE = Path(__file__).parent

img = Image.open(HERE / "images.jpeg").convert("RGB")
arr = np.array(img)  # shape: (H, W, 3) for RGB

row, col = arr.shape[0], arr.shape[1]  # H, W
assert row % 2 == 0 and col % 2 == 0, f"need even dims for RGGB, got {row}x{col}"

bayer = mosaic_rggb(arr)

bayer_flattened = bayer.flatten()  # row-major: row 0 left->right, then row 1, ...

np.savetxt(HERE / "array_data.mem", bayer_flattened, fmt="%02x")

with open(HERE / "array_data.meta", "w") as f:
    f.write(f"{row} {col}\n")  # H W

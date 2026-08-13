import numpy as np
from PIL import Image
from pathlib import Path

HERE = Path(__file__).parent

W, H = 64, 48

GREY  = (128, 128, 128)
GREEN = (40, 220, 50)
BLUE  = (30, 40, 200)

GX0, GX1 = 12, 50
GY0, GY1 = 8, 40

BX0, BX1 = 2, 9
BY0, BY1 = 30, 44

img = np.zeros((H, W, 3), dtype=np.uint8)
img[:, :] = GREY
img[BY0:BY1 + 1, BX0:BX1 + 1] = BLUE
img[GY0:GY1 + 1, GX0:GX1 + 1] = GREEN

np.savetxt(HERE / "color_test.mem", img.reshape(-1), fmt="%02x")
with open(HERE / "color_test.meta", "w") as f:
    f.write(f"{H} {W}\n")
Image.fromarray(img).save(HERE / "color_test.png")

print(f"wrote color_test.mem ({W}x{H} RGB), color_test.meta, color_test.png")
print(f"expected green box: min_x={GX0} max_x={GX1} min_y={GY0} max_y={GY1} valid=1")

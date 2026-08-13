from PIL import Image
from pathlib import Path
import numpy as np

HERE = Path(__file__).parent


def mosaic_rggb(arr):
    row, col = arr.shape[0], arr.shape[1]
    raw = np.zeros((row, col), dtype=np.uint8)
    for i in range(row):
        for j in range(col):
            if i % 2 == 0 and j % 2 == 0:
                raw[i, j] = arr[i, j, 0]   # red
            elif i % 2 == 1 and j % 2 == 1:
                raw[i, j] = arr[i, j, 2]   # blue
            else:
                raw[i, j] = arr[i, j, 1]   # green
    return raw


def colorize_mosaic(raw):
    row, col = raw.shape
    vis = np.zeros((row, col, 3), dtype=np.uint8)
    vis[0::2, 0::2, 0] = raw[0::2, 0::2]   # R positions -> red channel
    vis[0::2, 1::2, 1] = raw[0::2, 1::2]   # G
    vis[1::2, 0::2, 1] = raw[1::2, 0::2]   # G
    vis[1::2, 1::2, 2] = raw[1::2, 1::2]   # B
    return vis


if __name__ == "__main__":
    img = Image.open(HERE / "images.jpeg").convert("RGB")
    arr = np.array(img)  # shape: (H, W, 3) for RGB

    row = img.size[1]
    col = img.size[0]
    assert row % 2 == 0 and col % 2 == 0, f"need even dims, got {row}x{col}"

    # real image
    raw = mosaic_rggb(arr)
    Image.fromarray(colorize_mosaic(raw)).save(HERE / "output_color.png")

    # solid-red pass/fail test: every pixel pure red
    red = np.zeros((row, col, 3), dtype=np.uint8)
    red[:, :, 0] = 255
    red_raw = mosaic_rggb(red)
    Image.fromarray(colorize_mosaic(red_raw)).save(HERE / "red_test.png")
    print("red-position values (should be 255):", red_raw[0, 0], red_raw[0, 2])
    print("green-position values (should be 0):", red_raw[0, 1], red_raw[1, 0])
    print("blue-position values  (should be 0):", red_raw[1, 1])
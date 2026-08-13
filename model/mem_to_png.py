import numpy as np
from PIL import Image
from pathlib import Path
from mem_io import load_mem, load_meta

HERE = Path(__file__).parent

if __name__ == "__main__":
    h, w = load_meta(HERE / "array_data.meta")           # H W
    img = load_mem(HERE / "rtl_out_pipeline.mem", h-2, w-2)         # shape (H, W)
    Image.fromarray(img).save(HERE / "reconstructed_image.png")

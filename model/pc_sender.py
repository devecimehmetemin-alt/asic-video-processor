## Streams a Bayer frame to the FPGA over UART with SLIP framing.
##   python pc_sender.py <port> <frame.mem>
##   e.g. python pc_sender.py COM4 frame_in.mem
##
## The FPGA has no flow control. pixel_tx sends 3 RGB bytes out per 1 Bayer byte
## in, so feeding faster than ~3 byte periods per pixel makes it drop pixels
## (the image shears). PIX_DELAY holds the wire idle between pixels to pace it.
## needs pyserial:  pip install pyserial
import sys, time
import serial
from mem_io import load_mem

PORT = sys.argv[1] if len(sys.argv) > 1 else "COM4"
MEM  = sys.argv[2] if len(sys.argv) > 2 else "frame_in.mem"
BAUD = 115200
PIX_DELAY = 0.0003          # seconds idle per pixel, >= ~2 byte periods (174us)

END = 0xC0                  # frame marker
ESC = 0xDB

raw = load_mem(MEM)         # flat array of Bayer bytes
ser = serial.Serial(PORT, BAUD)

def put(b):
    ser.write(bytes([b]))

put(END)                    # mark the start of the frame
for pix in raw:
    p = int(pix)
    if p == 0xC0:
        put(ESC); put(0xDC)
    elif p == 0xDB:
        put(ESC); put(0xDD)
    else:
        put(p)
    ser.flush()
    time.sleep(PIX_DELAY)

ser.close()
print(f"sent {raw.size} pixels")
## note: box_overlay draws the PREVIOUS frame's box, so the box only appears
## from the 2nd frame onward - run this twice (or loop) for a live demo.

## Generates the gamma_lut function body for rtl/gamma.sv.
## The RTL and gamma_model.py must apply the identical curve, so both are
## derived from this one formula rather than hand-kept in step. Writes
## gamma_lut.txt -- paste its contents into gamma.sv.
##
## An unpacked array with an '{...} initialiser is not captured by every
## SystemVerilog frontend (synlig drops it, and the whole table synthesises
## away as undefined). A case statement is unambiguous, and it is also the
## honest description of the hardware: an ASIC has no way to preload an array
## at power-up, so a lookup table is combinational logic either way.
from pathlib import Path

HERE = Path(__file__).parent

GAMMA = 2.2

lut = [round((i / 255.0) ** (1.0 / GAMMA) * 255.0) for i in range(256)]

lines = []
lines.append("function automatic logic [7:0] gamma_lut(input logic [7:0] x);")
lines.append("    case (x)")
for i, v in enumerate(lut):
    lines.append(f"        8'h{i:02X}: gamma_lut = 8'h{v:02X};")
lines.append("        default: gamma_lut = 8'h00;")
lines.append("    endcase")
lines.append("endfunction")

out = "\n".join(lines) + "\n"
(HERE / "gamma_lut.txt").write_text(out)

print(f"wrote gamma_lut.txt ({len(lines)} lines, gamma {GAMMA})")
print(f"spot check: lut[0]={lut[0]} lut[1]={lut[1]} lut[128]={lut[128]} lut[255]={lut[255]}")

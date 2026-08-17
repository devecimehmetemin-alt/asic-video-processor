# ASIC Video Processor

The image signal processing spine from my
[FPGA video processor](https://github.com/devecimehmetemin-alt/fpga-video-processor)
taken through a full RTL-to-GDSII flow on the SkyWater 130 nm open PDK.

Same design and the same Python reference model, different back end.
Instead of mapping to LUTs and block RAM, the design is synthesised to standard cells,
floorplanned, placed, routed and signed off against DRC and LVS.

## Pipeline

```
Bayer raw -> black level -> white balance -> 3x3 window -> debayer -> gamma
```

The colour detector and box overlay are left out. The spine is what exercises
the interesting parts of the flow: two line buffers of real storage, an adder
tree, and a 256-entry lookup table.

Frames are 64x64, small enough to route and simulate at gate level in minutes.

## Toolchain

Everything is open source.

```
OpenLane 2      flow orchestration
Yosys           synthesis
OpenROAD        floorplan, placement, CTS, routing
Magic, KLayout  DRC and GDS
netgen          LVS
OpenSTA         timing
sky130A         PDK, sky130_fd_sc_hd standard cells
```

Installed through Nix. Icarus Verilog runs the gate-level simulation.

## Results

Signed off at a 20 ns clock (50 MHz).

```
sequential cells        1183
cell area               73293 um^2
die area                157116 um^2  (~0.16 mm^2)
core utilisation        51.0 %
setup violations        0
hold violations         0
DRC errors              0  (routing, Magic, KLayout)
LVS errors              0
```

Sweeping the clock constraint downward puts the critical path at 9.5 ns at the
slow corner, so 105 MHz before pipelining. Splitting that path with a register
stage is the next move if the frequency ever needs to go up.

`flow/isp_core/results.json` holds these figures as the flow emits them.

## Running it

Needs an OpenLane 2 environment and the sky130A PDK. From inside it:

```
./flow/run_asic.sh
```

That runs the flow end to end, simulates the routed netlist, compares the
output against the reference, and writes `results.json`. It exits non-zero if
the gate-level output does not match.

The golden frames are committed, so a fresh clone runs as is.
`model/gen_asic_frame.py` regenerates them if the frame size changes.

## Verification

The Python model is the specification, same as on the FPGA side.

Clean DRC and LVS mean the layout can be manufactured. Met timing means it runs
at speed. Neither tells you the chip computes the right pixels, and it is
perfectly possible to pass all three with a design that is quietly wrong.

So the routed netlist is simulated against the SkyWater cell models and its
output compared byte for byte against the reference frame. Two frames go
through back to back, which makes the line buffers clear properly between them
instead of only ever working from a cold reset.

Both match, exactly.

## Layout

```
rtl/    synthesisable SystemVerilog
sim/    tb_isp_core.sv is the gate-level testbench; the rest are the
        per-module unit tests and need XSim rather than Icarus
model/  Python reference model and golden frames
flow/   OpenLane configuration, run script, results
```

## Compared with the FPGA build

The two builds are not directly comparable. The FPGA build is the full 640-wide
design including colour detection and the UART front end, using 618 LUTs, 406
registers and one block RAM. This is the 64-wide spine alone, using 1183
flip-flops and 0.16 mm^2 of standard cells.

**Storage.** On the Artix-7 the two line buffers are inferred into a single
block RAM. sky130 provides no equivalent hard block, so the same 1024 bits are
implemented as 1024 flip-flops, which is 87% of the sequential cells in the
design. At 640 pixels per line this would not be practical and an SRAM macro
would be required instead.

**Gamma table.** The FPGA loads memory contents from the bitstream during
configuration, so a 256-entry initialised array costs almost no logic. An ASIC
has no configuration step, so the table is implemented as combinational logic.

**Clock frequency.** The FPGA design runs at 25 MHz because VGA requires a
25 MHz pixel clock, not because of any timing limit. Built out of context on
the Artix-7, the same isp_core reaches 183 MHz against 105 MHz here, and the
critical path sits in the same place on both: the window registers through the
debayer into the gamma lookup. The gap is process rather than architecture:
the Artix-7 is fabricated on 28 nm and sky130 on 130 nm, a considerably older
and slower technology. This is the main reason the ASIC build runs at the
lower frequency.

**Toolchain differences.** Three constructs needed rewriting for the ASIC front
end: RGB as a packed `[23:0]` bus rather than an unpacked array of three bytes,
the gamma table as a case statement, and the white balance gain written without
a function return. The first two were accepted by Vivado without warning and
mis-elaborated here, producing a design that passed DRC, LVS and timing closure
while computing incorrect pixel values. Only comparison against the Python
reference model caught it, which is why the gate-level check is part of the
flow rather than an optional step.


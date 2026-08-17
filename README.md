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
tree, and a 256-entry lookup table that has to become logic rather than a
preloaded memory.

Frames are 64x64, small enough to route and simulate at gate level in minutes.
The line buffers still dominate: 1024 of the 1183 flip-flops are pixel storage.

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

Sweeping the clock constraint downward puts the critical path at roughly
9.5 ns at the slow corner, so about 105 MHz before pipelining. The path runs
through the debayer's adder tree into the gamma lookup. Splitting that with a
register stage is the next move if the frequency ever needs to go up.

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

## Porting notes

The RTL is the FPGA design with three changes the ASIC synthesis front end
forced.

RGB moves between stages as a packed `[23:0]` bus instead of an unpacked array
of three bytes. The gamma table is a case statement rather than an initialised
array, because an FPGA loads memory contents from the bitstream at
configuration and an ASIC has no equivalent, so a table that needs a power-up
value has to be logic. The white balance gain is written without a function
return, which the synthesis frontend would not read.



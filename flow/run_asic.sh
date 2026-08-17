#!/usr/bin/env bash
# Runs the ASIC flow for isp_core and verifies the routed netlist against the
# Python golden model. Run from inside the OpenLane environment:
#   cd ~/openlane2 && nix-shell
#   ./flow/run_asic.sh
set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CFG=$ROOT/flow/isp_core/config.json
WORK=$ROOT/work/gl

for f in asic_in.mem asic_ref.mem; do
    [ -f "$ROOT/model/$f" ] || {
        echo "missing model/$f - regenerate with: python model/gen_asic_frame.py"
        exit 1
    }
done

echo "=== 1. RTL to GDSII ==="
openlane "$CFG"

RUN=$(ls -dt "$ROOT"/flow/isp_core/runs/*/ | head -1)
echo "run: $RUN"

echo "=== 2. gate-level verification ==="
# $readmemh resolves paths relative to the working directory, so the golden
# input and reference have to sit next to the simulation
mkdir -p "$WORK" && cd "$WORK"
cp "$ROOT/model/asic_in.mem" "$ROOT/model/asic_ref.mem" .

NL=$RUN/final/nl/isp_core.nl.v
PDK=$(dirname "$(find "$HOME/.volare" -name primitives.v -path '*sky130_fd_sc_hd*' | head -1)")

# -DGL makes the testbench instantiate the DUT without parameter overrides:
# the netlist has no parameters, they are baked in at synthesis
iverilog -g2012 -DGL -DFUNCTIONAL -DUNIT_DELAY= -o gl.vvp \
  "$PDK/primitives.v" "$PDK/sky130_fd_sc_hd.v" "$NL" \
  "$ROOT/sim/tb_isp_core.sv"
vvp gl.vvp | tee gl.log

echo "=== 3. results ==="
python3 - "$RUN/final/metrics.json" "$ROOT/flow/isp_core/results.json" <<'PY'
import json, sys
src, dst = sys.argv[1], sys.argv[2]
m = json.load(open(src))
keep = ["design__instance__count__class:sequential_cell", "design__instance__area",
        "design__die__area", "design__instance__utilization",
        "route__drc_errors", "magic__drc_error__count", "klayout__drc_error__count",
        "design__lvs_error__count", "timing__setup__wns", "timing__hold__wns",
        "timing__setup_vio__count", "timing__hold_vio__count"]
out = {k: m[k] for k in keep if k in m}
json.dump(out, open(dst, "w"), indent=2)
print(json.dumps(out, indent=2))
PY

grep -q "PASS: both frames match" gl.log \
  && echo "ASIC RESULT: PASS" \
  || { echo "ASIC RESULT: FAIL"; exit 1; }

# Fmax of isp_core on Artix-7, out of context: no top level, no MMCM, no pins.
# Same RTL and the same 64-wide parameters as the ASIC build, so the two Fmax
# figures measure identical logic.
#   vivado -mode batch -source flow/fmax_core.tcl
set part xc7a35tcpg236-1
set root [file normalize [file join [file dirname [info script]] ..]]
set outdir $root/work/fmax
file mkdir $outdir

set results {}

foreach period {10.0 7.0 5.0} {
    puts "########## PERIOD $period ns ##########"
    create_project -in_memory -part $part -force

    read_verilog -sv [list \
        $root/rtl/black_level.sv \
        $root/rtl/white_balance.sv \
        $root/rtl/line_buffer.sv \
        $root/rtl/window_3x3.sv \
        $root/rtl/debayer.sv \
        $root/rtl/gamma.sv \
        $root/rtl/isp_core.sv \
    ]

    set xdc $outdir/clk_$period.xdc
    set fh [open $xdc w]
    puts $fh "create_clock -period $period -name clk \[get_ports clk\]"
    close $fh
    read_xdc $xdc

    synth_design -top isp_core -part $part -mode out_of_context
    opt_design
    place_design
    phys_opt_design
    route_design

    set wns [get_property SLACK [get_timing_paths -delay_type max]]
    set path [get_timing_paths -delay_type max]
    set src [get_property STARTPOINT_PIN $path]
    set dst [get_property ENDPOINT_PIN $path]
    set achieved [expr {$period - $wns}]
    set fmax [expr {1000.0 / $achieved}]
    lappend results [format "period %5.1f  WNS %7.3f  path %6.3f ns  Fmax %6.1f MHz" \
                     $period $wns $achieved $fmax]
    lappend results "        $src -> $dst"
    report_utilization -file $outdir/util_$period.rpt
    close_project
}

puts "\n=========== ISP_CORE FMAX (Artix-7, OOC) ==========="
foreach r $results { puts $r }
puts "===================================================="

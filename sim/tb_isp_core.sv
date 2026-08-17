`timescale 1ns/1ps

module tb_isp_core;

localparam int W = 64;
localparam int H = 64;
localparam int IW = W - 2;
localparam int IH = H - 2;
localparam int N_IN = W * H;
localparam int N_OUT = IW * IH * 3;
localparam int GAP = 20;

logic clk = 0;
logic reset, valid, frame_start;
logic [7:0] pix_in;
logic [23:0] pix_out;
logic valid_out;

always #5 clk = ~clk;

logic [7:0] frame_in [0:N_IN-1];
logic [7:0] frame_ref [0:N_OUT-1];
logic [7:0] rx [0:2*N_OUT-1];
int rx_n = 0;
int errors = 0;

`ifdef GL
isp_core dut (
    .clk, .reset, .valid, .frame_start,
    .pix_in, .pix_out, .valid_out
);
`else
isp_core #(.img_width(W), .img_height(H)) dut (
    .clk, .reset, .valid, .frame_start,
    .pix_in, .pix_out, .valid_out
);
`endif

always @(posedge clk) begin
    if (valid_out && rx_n + 2 < 2*N_OUT) begin
        rx[rx_n] = pix_out[23:16];
        rx[rx_n+1] = pix_out[15:8];
        rx[rx_n+2] = pix_out[7:0];
        rx_n += 3;
    end
end

task send_pixel(input logic [7:0] p);
    pix_in = p;
    valid = 1'b1;
    @(negedge clk);
endtask

task send_frame;
    frame_start = 1'b1;
    @(negedge clk);
    frame_start = 1'b0;
    for (int i = 0; i < N_IN; i++) send_pixel(frame_in[i]);
    valid = 1'b0;
endtask

task automatic check_frame(input int base, input string name);
    int n = 0;
    for (int i = 0; i < N_OUT; i++) begin
        if (rx[base+i] !== frame_ref[i]) begin
            if (n < 5)
                $display("FAIL: %s byte %0d got %02h expected %02h",
                         name, i, rx[base+i], frame_ref[i]);
            n++;
        end
    end
    if (n == 0) $display("PASS: %s matches (%0d bytes)", name, N_OUT);
    else $display("FAIL: %s has %0d mismatches", name, n);
    errors += n;
endtask

initial begin
    $readmemh("asic_in.mem", frame_in);
    $readmemh("asic_ref.mem", frame_ref);

    reset = 1'b1;
    valid = 1'b0;
    frame_start = 1'b0;
    pix_in = 8'h00;
    repeat (4) @(negedge clk);
    reset = 1'b0;
    repeat (2) @(negedge clk);

    send_frame;
    repeat (GAP) @(negedge clk);
    send_frame;
    repeat (64) @(negedge clk);

    if (rx_n != 2*N_OUT) begin
        $display("FAIL: got %0d bytes, expected %0d", rx_n, 2*N_OUT);
        errors++;
    end

    check_frame(0, "frame 1");
    check_frame(N_OUT, "frame 2");

    $writememh("rx_out.mem", rx);

    if (errors == 0) $display("PASS: both frames match");
    else $display("FAIL: %0d total mismatches", errors);

    $finish;
end

endmodule

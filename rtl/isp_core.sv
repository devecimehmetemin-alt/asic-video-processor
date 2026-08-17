module isp_core #(
    parameter int img_width = 64,
    parameter int img_height = 64
)(
    input logic clk, reset, valid, frame_start,
    input logic [7:0] pix_in,
    output logic [23:0] pix_out,
    output logic valid_out
);

logic [7:0] bl_pix;
logic bl_valid;
logic [7:0] wb_pix;
logic wb_valid;
logic [7:0] w11, w12, w13, w21, w22, w23, w31, w32, w33;
logic win_valid;
logic [23:0] deb_pix;
logic deb_valid;
logic [23:0] g_pix;
logic fs_d1, fs_d2;

always_ff @(posedge clk) begin
    if (reset) begin
        fs_d1 <= 1'b0;
        fs_d2 <= 1'b0;
    end else begin
        fs_d1 <= frame_start;
        fs_d2 <= fs_d1;
    end
end

black_level #(.img_width(img_width)) u_black_level (
    .clk, .reset, .valid, .frame_start,
    .pix_in(pix_in),
    .pix_out(bl_pix),
    .valid_out(bl_valid)
);

white_balance #(.img_width(img_width)) u_white_balance (
    .clk, .reset,
    .frame_start(fs_d1),
    .valid(bl_valid),
    .pix_in(bl_pix),
    .pix_out(wb_pix),
    .valid_out(wb_valid)
);

window_3x3 #(.img_width(img_width), .img_height(img_height)) u_window_3x3 (
    .clk, .reset,
    .frame_start(fs_d2),
    .valid(wb_valid),
    .pix_in(wb_pix),
    .w11, .w12, .w13, .w21, .w22, .w23, .w31, .w32, .w33,
    .valid_out(win_valid)
);

debayer #(.img_width(img_width), .img_height(img_height)) u_debayer (
    .clk, .reset,
    .valid(win_valid),
    .w11, .w12, .w13, .w21, .w22, .w23, .w31, .w32, .w33,
    .pix_out(deb_pix),
    .valid_out(deb_valid)
);

gamma u_gamma (
    .clk, .reset,
    .valid(deb_valid),
    .pix_in(deb_pix),
    .pix_out(g_pix),
    .valid_out(valid_out)
);

assign pix_out = g_pix;

endmodule

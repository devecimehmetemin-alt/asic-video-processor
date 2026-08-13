module line_buffer#(
    parameter int img_width = 640
) (
    input clk, 
    input [7:0] pix_in, 
    input valid, 
    input reset,
    output logic [7:0] pix_out,
    output logic [7:0] pix_in_delay,
    output logic valid_out
);

logic [7:0] line [img_width-1:0];
logic [$clog2(img_width)-1:0] i = 0;
logic full = 0;

always_ff @(posedge clk) begin
    if (valid) begin
        line[i] <= pix_in;
        i <= (i < img_width-1) ? (i+1) : '0;
        pix_out <= line[i];
        pix_in_delay <= pix_in;
    end

    if(reset) begin
        i <= 0;
        full <= 1'b0;
        valid_out <= 0;
    end else begin
        if (i == img_width - 1) begin
            full <= 1'b1;
        end
        valid_out <= full && valid ;
    end
    
end


endmodule
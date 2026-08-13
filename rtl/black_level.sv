module black_level #(
    parameter int img_width = 640
) (
    input clk, 
    input reset, 
    input [7:0] pix_in, 
    input valid, 
    input frame_start,
    output logic [7:0] pix_out,
    output logic valid_out
);

localparam int red = 5;
localparam int green = 10;
localparam int blue = 15;

localparam logic [1:0] ch_red = 2'b00;
localparam logic [1:0] ch_green = 2'b01;
localparam logic [1:0] ch_blue = 2'b10;

logic [1:0] channel;
logic [7:0] offset;
logic [9:0] col_count;  
logic       row_parity;


always_ff @(posedge clk) begin
    if (valid) pix_out <= (pix_in > offset) ? (pix_in - offset) : 8'b0;
    if (reset) valid_out <= 1'b0;
    else valid_out <= valid;
end

// counter for position, to be used to determine R,G,B of photosensor present
always_ff @(posedge clk) begin
    if(reset || frame_start) begin
        col_count <= 0;
        row_parity <= 0;
    end 
    else if (valid) begin
        if (col_count == img_width-1) begin
            col_count <= 0;
            row_parity <= ~row_parity;   // flip between 0 and 1
        end
        else begin
            col_count <= col_count + 1;
        end
    end
end

always_comb begin
    if(row_parity == 0 && col_count[0] == 0 ) begin
        channel = ch_red;
    end    
    else if (row_parity == 1 && col_count[0] == 1) begin
        channel = ch_blue;
    end
    else begin
        channel = ch_green;
    end
end

always_comb begin
    case (channel)
        ch_red:
            offset = red;
        ch_blue:
            offset = blue;
        default:
            offset = green;
    endcase
end
endmodule
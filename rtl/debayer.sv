module debayer #(
    parameter int img_width = 640,
    parameter int img_height = 480
) (
    input clk, 
    input valid, 
    input reset,
    input logic [7:0] w11, w12, w13, // row 1
    input logic [7:0] w21, w22, w23, // row 2
    input logic [7:0] w31,w32, w33, // row 3
    output logic [23:0] pix_out, 
    output logic valid_out
);

logic [1:0] channel;
logic [$clog2(img_width)-1:0] col_count = 0;
logic row_parity; 
localparam logic [1:0] ch_green_red_row = 2'b00;
localparam logic [1:0] ch_green_blue_row = 2'b01;
localparam logic [1:0] ch_red = 2'b10;
localparam logic [1:0] ch_blue = 2'b11;

always_ff @(posedge clk ) begin
    if(reset) begin
            col_count <= 1;
            row_parity <= 1;
        end 
    else if (valid) begin
        if (col_count == img_width-2) begin
            col_count <= 1;
            row_parity <= ~row_parity;   // flip between 0 and 1
        end
        else begin
            col_count <= col_count + 1;
        end
    end
end

assign valid_out = valid;

always_comb begin
    if(row_parity == 0 && col_count[0] == 0 ) begin
        channel = ch_red;
    end    
    else if (row_parity == 1 && col_count[0] == 1) begin
        channel = ch_blue;
    end
    else if (row_parity == 0 && col_count[0] == 1) begin
        channel = ch_green_red_row;
    end
    else begin
        channel = ch_green_blue_row;
    end
end

always_comb begin
        case (channel)
            ch_red:begin
                pix_out[23:16] = w22;
                pix_out[15:8] = (10'(w12) + w21 + w23 + w32) >> 2;
                pix_out[7:0] = (10'(w11) + w13 + w31 + w33) >> 2;
            end
            ch_blue: begin
                pix_out[23:16] = (10'(w11) + w13 + w31 + w33) >> 2;
                pix_out[15:8] = (10'(w12) + w21 + w23 + w32) >> 2;
                pix_out[7:0] =  w22;
            end
            ch_green_red_row: begin
                pix_out[23:16] = (9'(w21) + w23) >> 1;
                pix_out[15:8] = w22;
                pix_out[7:0] = (9'(w12) + w32) >> 1;
            end
            default: begin // ch_green_blue_row
                pix_out[23:16] = (9'(w12) + w32) >> 1;
                pix_out[15:8] = w22;
                pix_out[7:0] = (9'(w21) + w23) >> 1;
            end
        endcase
    end



endmodule
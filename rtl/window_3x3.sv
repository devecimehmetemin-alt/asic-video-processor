module window_3x3 #(
    parameter int img_width = 640,
    parameter int img_height = 480
) (
    input clk,
    input [7:0] pix_in,
    input valid,
    input reset,
    input frame_start,
    output logic [7:0] w11, w12, w13, // row 1
    output logic [7:0] w21, w22, w23, // row 2
    output logic [7:0] w31, w32, w33, // row 3
    output logic valid_out
);

logic [7:0] line_buffer_1 [img_width-1:0];
logic [7:0] line_buffer_2 [img_width-1:0];
logic [$clog2(img_width)-1:0] col_count = 0;
logic [$clog2(img_height)-1:0] row_count = 0;

// asynchronous reads: the buffers hold the previous row until the write at the
// clock edge overwrites them, so read-before-write is structural rather than a
// read-during-write policy the synthesiser has to infer
logic [7:0] lb1_dout, lb2_dout;
assign lb1_dout = line_buffer_1[col_count];
assign lb2_dout = line_buffer_2[col_count];

always_ff @(posedge clk) begin
    
    if(reset || frame_start) begin
        col_count <= 0;
        row_count <= 0;
        valid_out <= 0;
    end
    else if (valid) begin
        if (col_count == img_width-1) begin
            col_count <= 0;
            row_count <= (row_count == img_height-1) ? 0 : row_count + 1;
        end
        else begin
            col_count <= col_count + 1;  // track col position
        end
    end

    if (valid) begin
        line_buffer_1[col_count] <= pix_in;
        line_buffer_2[col_count] <= lb1_dout;
    end

    if(valid && col_count > 1 && row_count > 1) begin
        valid_out <= 1;
    end else begin
        valid_out <= 0;
    end 

    if(valid) begin
        // row 3
        w33 <= pix_in;
        w32 <= w33;
        w31 <= w32;

        // row 2
        w23 <= lb1_dout;
        w22 <= w23;
        w21 <= w22;

        //row 1
        w13 <= lb2_dout;
        w12 <= w13;
        w11 <= w12;
    end
end

endmodule
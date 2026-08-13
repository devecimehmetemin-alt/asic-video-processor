module white_balance #(
    parameter int img_width = 640
    )(
        input clk,
        input [7:0] pix_in,
        input valid,
        input reset,
        input frame_start, 
        output logic [7:0] pix_out, 
        output logic valid_out
    );

    localparam logic [9:0] g_red = 358;
    localparam logic [9:0] g_green = 256;
    localparam logic [9:0] g_blue = 512; // 1.4,1,2 converted into fixed point gain

    localparam logic [1:0] ch_red = 2'b00;
    localparam logic [1:0] ch_green = 2'b01;
    localparam logic [1:0] ch_blue = 2'b10;

    logic [1:0] channel;
    logic [9:0] col_count;  
    logic       row_parity; 
    logic [9:0] gain;

    function automatic logic [7:0] apply_gain(
        input logic [7:0] pix,
        input logic [9:0] gain
    );
        logic [7:0] result;
        logic [17:0] multiplication = pix * gain;
        logic [9:0] i_result = multiplication >> 8; //product truncated

        result = (i_result > 255) ? 8'd255 : (i_result) ; // saturate at 255
        return result;
    endfunction

    always_ff @(posedge clk) begin
        if (valid) pix_out <= apply_gain(pix_in, gain);
        if (reset) valid_out <= 1'b0;
        else valid_out <= valid;
    end     

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
                gain = g_red;
            ch_blue:
                gain = g_blue;
            default:
                gain = g_green;
        endcase
    end

endmodule




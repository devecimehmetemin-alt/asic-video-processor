module tb_debayer();
    localparam int W = 678, H = 452;      // from array_data.meta
    localparam int N = (W)*(H);

    logic clk;
    logic [7:0] mem_in [0:N-1];
    logic [7:0] mem_out [0:3*(W-2)*(H-2)-1];
    logic reset, valid_out_win, valid_out_deb;
    logic valid = 0;
    logic [$clog2(N+1)-1:0] j = 0, k = 0;
    logic [7:0] w11, w12, w13, w21, w22, w23, w31, w32, w33;
    logic [7:0] pix_out [2:0];
    wire [7:0] pix_in;

    assign pix_in = mem_in[j];
    
    // Clock generation
    initial clk = 0;
    always #20 clk = ~clk;  // 25MHz

    // instantiation of window_3x3 module
    window_3x3 #(.img_width(W), .img_height(H)) WIN(
        .clk, .pix_in(pix_in), .valid, .reset, .frame_start(1'b0), .w11, .w12, .w13, .w21, .w22, .w23, .w31, .w32, .w33, .valid_out(valid_out_win)
    );

    // instantiation of debayer module
    debayer #(.img_width(W), .img_height(H)) DUT(
        .clk, .valid(valid_out_win), .reset, .w11, .w12, .w13, .w21, .w22, .w23, .w31, .w32, .w33, .pix_out(pix_out), .valid_out(valid_out_deb)
    );

    initial begin 
        $dumpfile("tb_debayer.vcd");
        $dumpvars(0, tb_debayer); 
        $readmemh("array_data.mem", mem_in);
        reset <= 1;
        #120; //wait 3 cycles before process starts
        reset <= 0; 
        valid <= 1;
    end

    always_ff @(posedge clk ) begin
        if (valid) begin
            if (j == N-1) valid <= 0;
            else          j <= j + 1;
        end

        if (valid_out_deb) begin
            mem_out[3*k]<=pix_out[0];
            mem_out[3*k+1]<=pix_out[1]; 
            mem_out[3*k+2]<=pix_out[2];
            k <= k + 1;
        end
    end

    always_ff @(negedge clk ) begin
        if (k == (W-2)*(H-2)) begin
            $writememh("rtl_out_debayer.mem", mem_out);
            $finish; //finish program
        end    
    end

endmodule
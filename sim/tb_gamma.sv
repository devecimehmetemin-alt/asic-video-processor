module tb_gamma;
    localparam int W = 678, H = 452;      // from array_data.meta
    localparam int N = (W-2)*(H-2);
    
    logic clk;
    logic [7:0] mem_in [0:3*N-1];
    logic [7:0] mem_out [0:3*N-1];
    logic reset, valid_out;
    logic valid = 0;
    logic [$clog2(N+1)-1:0] j = 0, k = 0;
    logic [7:0] pix_out [2:0];
    wire [7:0] pix_in [2:0];

    // Instantiate DUT
    gamma DUT (
        .clk,
        .reset,
        .valid,
        .pix_in,
        .valid_out,
        .pix_out
    );

    assign pix_in[0] = mem_in[3*j];
    assign pix_in[1] = mem_in[3*j+1];
    assign pix_in[2] = mem_in[3*j+2];
    
    // Clock generation
    initial clk = 0;
    always #20 clk = ~clk;  // 25MHz

    initial begin 
        $dumpfile("tb_gamma.vcd");
        $dumpvars(0, tb_gamma); 
        $readmemh("rtl_out_debayer.mem", mem_in);
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

        if (valid_out) begin
            mem_out[3*k]<=pix_out[0];
            mem_out[3*k+1]<=pix_out[1]; 
            mem_out[3*k+2]<=pix_out[2];
            k <= k + 1;
        end
    end

    always_ff @(negedge clk ) begin
        if (k == (W-2)*(H-2)) begin
            $writememh("rtl_out_gamma.mem", mem_out);
            $finish; //finish program
        end    
    end




endmodule

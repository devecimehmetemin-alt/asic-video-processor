module tb_line_buffer();
    localparam int W = 4, H = 3;      // from array_data.meta
    localparam int N = W * H; 

    logic clk;
    logic [7:0] mem_in [0:N-1];
    logic [7:0] mem_expected [0:N-1];
    //logic [7:0] mem_out [0:N-1];
    logic reset, valid, valid_out, start;
    logic [7:0] pix_in, pix_out, pix_in_delay;
    logic [$clog2(N+1)-1:0] j,k;

    // Clock generation
    initial clk = 0;
    always #20 clk = ~clk;  // 25MHz

    // instantiation of module black_level
    line_buffer #(.img_width(W)) DUT(
        .clk, .pix_in, .valid, .reset, .pix_out, .pix_in_delay, .valid_out
    );

    initial 
        begin 
            $dumpfile("tb_line_buffer.vcd");
            $dumpvars(0, tb_line_buffer); 
            $readmemh("trial.mem", mem_in);
            $readmemh("expected.mem", mem_expected);
            j <= 0; //start count
            k <= 0; //valid_out count
            start <= 0;
            reset <= 1;
            valid <= 0;
            #120; //wait 3 cycles before process starts
            reset <= 0; 
            start <= 1;
            #40;
        end

    always_ff @(posedge clk) begin
        valid <= start;
        if (start) begin
            j <= j + 1;
            pix_in <= mem_in[j];
        end
        if (valid_out) begin
            //mem_out[k] <= pix_out;
            k <= k + 1;
        end
    end

    always_ff @( negedge clk ) begin 
        if (valid_out) begin
            assert (mem_expected[j-2] == pix_out)  //expect pix out = 1 for pix in = 5
            else $error("j=%0d pix_out=%0d pix expected=%0d",
            j, pix_out, mem_expected[j-2]);
        end
    end

    always @(posedge clk ) begin
        if (k == N-W-1) begin
            //$writememh("output_line_buffer.mem", mem_out);
            $finish; //finish program
        end
    end

endmodule
module tb_black_level();
    localparam int W = 678, H = 452;      // from array_data.meta
    localparam int N = W * H;
    localparam logic [7:0] red=8'd5, green=8'd10, blue=8'd15;  

    logic clk;
    logic [7:0] mem_in [0:N-1];
    logic [7:0] mem_out [0:N-1];
    logic reset, valid, frame_start, valid_out, start;
    logic [7:0] pix_in, pix_out, pix_in_delay, exp_ped, exp_ped_delay;
    logic [$clog2(N+1)-1:0] j,k;

    // Clock generation
    initial clk = 0;
    always #20 clk = ~clk;  // 25MHz

    // instantiation of module black_level
    black_level #(.img_width(W)) DUT(
        .clk, .reset, .pix_in, .valid, .frame_start, .pix_out, .valid_out
    );

    initial 
        begin 
            $dumpfile("tb_black_level.vcd");
            $dumpvars(0, tb_black_level); 
            $readmemh("array_data.mem", mem_in);
            j <= 0; //start count
            k <= 0; //valid_out count
            reset <= 1;
            frame_start <=0;
            valid <= 0;
            #120; //wait 3 cycles before process starts
            reset <= 0; 
            frame_start <= 1;
            start <= 1;
            #40
            frame_start <= 0;
        end


    always_ff @(posedge clk) begin
        int row = j / W;
        int col = j % W;
        
        valid <= start;

        if (start) begin
            j <= j + 1;
            pix_in_delay <= pix_in;
            exp_ped_delay <= exp_ped;
            pix_in <= mem_in[j];
        end
        if (valid_out) begin
            mem_out[k] <= pix_out;
            k <= k + 1;
        end

        // rgb mapping:
        if      (row[0]==0 && col[0]==0) exp_ped <= red;
        else if (row[0]==1 && col[0]==1) exp_ped <= blue;
        else                             exp_ped <= green;
    end

    always_ff @( negedge clk ) begin 
        if (valid_out) begin
            assert (pix_in_delay >= exp_ped_delay ? pix_in_delay - pix_out == exp_ped_delay : pix_out == 8'h0)
            else $error("pix_in=%0d pix_out=%0d ped=%0d",
            pix_in_delay, pix_out, exp_ped_delay);
        end
    end

    always @(posedge clk ) begin
        if (k == N) begin
            $writememh("output_black_level.mem", mem_out);
            $finish; //finish program
        end
    end

endmodule
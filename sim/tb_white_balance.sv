module tb_white_balance();
    localparam int W = 678, H = 452;      // from array_data.meta
    localparam int N = W * H;
    localparam logic [9:0] g_red = 358;
    localparam logic [9:0] g_green = 256;
    localparam logic [9:0] g_blue = 512;

    logic clk;
    logic [7:0] mem_in [0:N-1];
    logic [7:0] mem_out [0:N-1];
    logic reset, frame_start, valid_out;
    logic start = 0;
    logic valid = 0;
    logic [$clog2(N+1)-1:0] j = 0, k = 0;
    logic [7:0] pix_in, pix_out, pix_out_delay, pix_in_delay, pix_in_double_delay, exp_pix;
    logic [17:0] exp_prod;

    

    // Clock generation
    initial clk = 0;
    always #20 clk = ~clk;  // 25MHz

    // instantiation of module white_balance
    white_balance #(.img_width(W)) DUT(
        .clk, .reset, .pix_in, .valid, .frame_start, .pix_out, .valid_out
    );

    initial 
        begin 
            $dumpfile("tb_white_balance.vcd");
            $dumpvars(0, tb_white_balance); 
            $readmemh("rtl_out_black_level.mem", mem_in);
            reset <= 1;
            frame_start <=0;
            #120; //wait 3 cycles before process starts
            reset <= 0; 
            frame_start <= 1;
            start <= 1;
            #40
            frame_start <= 0;
        end

    //exp_prod = pix_in_delay * tb_gain;                      
    //exp_pix  = (exp_prod[17:16] != 0) ? 8'd255 : exp_prod[15:8];

    always_ff @(posedge clk) begin
        int row;
        int col;
        row = j>1 ? (j-2) / W : 0;
        col = j>1 ? (j-2) % W : 0; // j-2 accounts for the delay
        
        valid <= start;

        if (start) begin
            j <= j + 1;
            pix_in_delay <= pix_in;
            pix_in_double_delay <= pix_in_delay;
            pix_out_delay <= pix_out; // 2-cycle delay introduced for syncing
            pix_in <= mem_in[j];
        end
        if (valid_out) begin
            mem_out[k] <= pix_out;
            k <= k + 1;
        end

        // rgb mapping:
        if      (row[0]==0 && col[0]==0) begin
            exp_prod = pix_in_delay * g_red;
            exp_pix  <= (exp_prod[17:16] != 0) ? 8'd255 : exp_prod[15:8];
        end
        else if (row[0]==1 && col[0]==1) begin
            exp_prod = pix_in_delay * g_blue;
            exp_pix  <= (exp_prod[17:16] != 0) ? 8'd255 : exp_prod[15:8];
        end
        else begin
            exp_prod = pix_in_delay * g_green;
            exp_pix  <= (exp_prod[17:16] != 0) ? 8'd255 : exp_prod[15:8];
        end
    end

    always_ff @( negedge clk ) begin 
        if (valid_out) begin
            if (j>2) begin
                assert (exp_pix == pix_out_delay)
                else $error("pix_in=%0d pix_out=%0d pix_expected=%0d",
                pix_in_double_delay, pix_out_delay, exp_pix);
            end
        end
    end

    always @(posedge clk ) begin
        if (k == N) begin
            $writememh("rtl_out_white_level.mem", mem_out);
            $finish; //finish program
        end
    end

endmodule
module tb_window_3x3();
    localparam int W = 5, H = 5;      // from array_data.meta
    localparam int N = W * H; 

    logic clk;
    logic [7:0] mem_in [0:N-1];
    //logic [7:0] mem_out [0:N-1];

    logic reset, valid, valid_out;
    wire  [7:0] pix_in;
    int   index;
    logic [7:0] image [0:H-1][0:W-1];
    logic [$clog2(H+1)-1:0] o_row;   
    logic [$clog2(W+1)-1:0] o_col;   
    logic [$clog2(N+1)-1:0] j, k;
    logic [7:0] w11, w12, w13, w21, w22, w23, w31, w32, w33;
    // 1-cycle-delayed copy of the counter = window bottom-right corner on the bus
    logic [$clog2(H+1)-1:0] o_row_d1;
    logic [$clog2(W+1)-1:0] o_col_d1;

    // combinational stimulus: pix_in and valid both reflect j the same cycle
    assign pix_in = mem_in[j];

    // Clock generation
    initial clk = 0;
    always #20 clk = ~clk;  // 25MHz

    // instantiation of window_3x3 module
    window_3x3 #(.img_width(W), .img_height(H)) DUT(
        .clk, .pix_in, .valid, .reset, .frame_start(1'b0), .w11, .w12, .w13, .w21, .w22, .w23, .w31, .w32, .w33, .valid_out
    );

    task automatic initialize_image;
        index = 0;
        begin
            for (int row = 0; row < H; row++) begin
                for (int col = 0; col < W; col++) begin
                    image[row][col] = mem_in[index];
                    index = index + 1;
                end
            end
        end
    endtask

    task automatic check_pixel(
        input string name,
        input logic [7:0] actual,
        input logic [7:0] expected
    );
        begin
            if (actual !== expected) begin
                $error(
                "%s mismatch at output window row=%0d col=%0d: expected=%0d, actual=%0d",
                name,
                o_row_d1,
                o_col_d1,
                expected,
                actual
                );
            end
        end
    endtask

    task automatic check_window;
        begin
            check_pixel("w11", w11, image[o_row_d1-2][o_col_d1-2]);
            check_pixel("w12", w12, image[o_row_d1-2][o_col_d1-1]);
            check_pixel("w13", w13, image[o_row_d1-2][o_col_d1]);

            check_pixel("w21", w21, image[o_row_d1-1][o_col_d1-2]);
            check_pixel("w22", w22, image[o_row_d1-1][o_col_d1-1]);
            check_pixel("w23", w23, image[o_row_d1-1][o_col_d1]);

            check_pixel("w31", w31, image[o_row_d1][o_col_d1-2]);
            check_pixel("w32", w32, image[o_row_d1][o_col_d1-1]);
            check_pixel("w33", w33, image[o_row_d1][o_col_d1]);

            $display("Checked window at row=%0d col=%0d: ", o_row_d1, o_col_d1);
            //"[%0d %0d %0d; %0d %0d %0d; %0d %0d %0d]",
        end
    endtask

    initial 
        begin 
            $dumpfile("tb_window_3x3.vcd");
            $dumpvars(0, tb_window_3x3); 
            $readmemh("trial.mem", mem_in);
            j <= 0; //start count
            k <= 0; //valid_out count
            reset <= 1;
            valid <= 0;
            #120; //wait 3 cycles before process starts
            reset <= 0; 
            valid <= 1;
            #40;
            initialize_image();
        end

        always_ff @( negedge clk ) begin 
            if(valid_out) begin
                check_window();
                k <= k + 1;
            end  

        end

        always_ff@( posedge clk) begin
            if (reset) begin
                o_col <= 0;
                o_row <= 0;
                o_col_d1 <= 0;
                o_row_d1 <= 0;
            end
            if (valid) begin
                if (j == N-1) valid <= 0;   // last real pixel is on pix_in this cycle
                else           j <= j + 1;

                if (o_col == W - 1) begin
                    o_col <= 0;
                    o_row <= o_row + 1;
                end
                else begin
                    o_col <= o_col + 1;
                end

                // delay the counter by 1 to line up with the window on the bus
                o_col_d1 <= o_col;
                o_row_d1 <= o_row;
            end
        end


        always @(posedge clk) begin
            if (k == (W-2)*(H-2)) begin
                $finish; //finish program
            end
        end
endmodule
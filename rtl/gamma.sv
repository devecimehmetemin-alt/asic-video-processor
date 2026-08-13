module gamma (
    input  logic clk,
    input  logic reset,
    input  logic valid,
    input  logic [7:0] pix_in [2:0],
    output logic valid_out,
    output logic [7:0] pix_out [2:0]
);

    // Gamma correction Look-Up Table
    // Gamma = 2.2
    // Formula: output = round((input / 255.0) ** (1.0 / 2.2) * 255.0)

(* rom_style = "distributed" *) logic [7:0] GAMMA_LUT [0:255] = '{
        8'h00, 8'h15, 8'h1C, 8'h22, 8'h27, 8'h2B, 8'h2E, 8'h32,
        8'h35, 8'h38, 8'h3B, 8'h3D, 8'h40, 8'h42, 8'h44, 8'h46,
        8'h48, 8'h4A, 8'h4C, 8'h4E, 8'h50, 8'h52, 8'h54, 8'h55,
        8'h57, 8'h59, 8'h5A, 8'h5C, 8'h5D, 8'h5F, 8'h60, 8'h62,
        8'h63, 8'h65, 8'h66, 8'h67, 8'h69, 8'h6A, 8'h6B, 8'h6D,
        8'h6E, 8'h6F, 8'h70, 8'h72, 8'h73, 8'h74, 8'h75, 8'h76,
        8'h77, 8'h78, 8'h7A, 8'h7B, 8'h7C, 8'h7D, 8'h7E, 8'h7F,
        8'h80, 8'h81, 8'h82, 8'h83, 8'h84, 8'h85, 8'h86, 8'h87,
        8'h88, 8'h89, 8'h8A, 8'h8B, 8'h8C, 8'h8D, 8'h8E, 8'h8F,
        8'h90, 8'h90, 8'h91, 8'h92, 8'h93, 8'h94, 8'h95, 8'h96,
        8'h97, 8'h97, 8'h98, 8'h99, 8'h9A, 8'h9B, 8'h9C, 8'h9C,
        8'h9D, 8'h9E, 8'h9F, 8'hA0, 8'hA0, 8'hA1, 8'hA2, 8'hA3,
        8'hA4, 8'hA4, 8'hA5, 8'hA6, 8'hA7, 8'hA7, 8'hA8, 8'hA9,
        8'hAA, 8'hAA, 8'hAB, 8'hAC, 8'hAD, 8'hAD, 8'hAE, 8'hAF,
        8'hAF, 8'hB0, 8'hB1, 8'hB2, 8'hB2, 8'hB3, 8'hB4, 8'hB4,
        8'hB5, 8'hB6, 8'hB6, 8'hB7, 8'hB8, 8'hB8, 8'hB9, 8'hBA,
        8'hBA, 8'hBB, 8'hBC, 8'hBC, 8'hBD, 8'hBE, 8'hBE, 8'hBF,
        8'hC0, 8'hC0, 8'hC1, 8'hC2, 8'hC2, 8'hC3, 8'hC3, 8'hC4,
        8'hC5, 8'hC5, 8'hC6, 8'hC7, 8'hC7, 8'hC8, 8'hC8, 8'hC9,
        8'hCA, 8'hCA, 8'hCB, 8'hCB, 8'hCC, 8'hCD, 8'hCD, 8'hCE,
        8'hCE, 8'hCF, 8'hCF, 8'hD0, 8'hD1, 8'hD1, 8'hD2, 8'hD2,
        8'hD3, 8'hD4, 8'hD4, 8'hD5, 8'hD5, 8'hD6, 8'hD6, 8'hD7,
        8'hD7, 8'hD8, 8'hD9, 8'hD9, 8'hDA, 8'hDA, 8'hDB, 8'hDB,
        8'hDC, 8'hDC, 8'hDD, 8'hDD, 8'hDE, 8'hDF, 8'hDF, 8'hE0,
        8'hE0, 8'hE1, 8'hE1, 8'hE2, 8'hE2, 8'hE3, 8'hE3, 8'hE4,
        8'hE4, 8'hE5, 8'hE5, 8'hE6, 8'hE6, 8'hE7, 8'hE7, 8'hE8,
        8'hE8, 8'hE9, 8'hE9, 8'hEA, 8'hEA, 8'hEB, 8'hEB, 8'hEC,
        8'hEC, 8'hED, 8'hED, 8'hEE, 8'hEE, 8'hEF, 8'hEF, 8'hF0,
        8'hF0, 8'hF1, 8'hF1, 8'hF2, 8'hF2, 8'hF3, 8'hF3, 8'hF4,
        8'hF4, 8'hF5, 8'hF5, 8'hF6, 8'hF6, 8'hF7, 8'hF7, 8'hF8,
        8'hF8, 8'hF9, 8'hF9, 8'hF9, 8'hFA, 8'hFA, 8'hFB, 8'hFB,
        8'hFC, 8'hFC, 8'hFD, 8'hFD, 8'hFE, 8'hFE, 8'hFF, 8'hFF
    };

    // Pipeline registers for video timing/synchronization
    always_ff @(posedge clk) begin
        if (reset) begin
            valid_out <= 1'b0;
            pix_out[0]     <= 8'd0;
            pix_out[1]     <= 8'd0;
            pix_out[2]     <= 8'd0;
        end 
        else begin
            valid_out <= valid;
            if (valid) begin
                pix_out[0] <= GAMMA_LUT[pix_in[0]];
                pix_out[1] <= GAMMA_LUT[pix_in[1]];
                pix_out[2] <= GAMMA_LUT[pix_in[2]];
            end
        end
    end
endmodule
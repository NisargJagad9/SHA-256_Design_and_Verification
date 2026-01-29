

`timescale 1ns / 1ps
`include "sha_functions.sv" 

module msg_sch(
    input  logic clk,
    input  logic rst_n, 
    // Input lines from preprocessor
    input  logic [31:0] M_i,
    input  logic M_dv,
    // Output lines for hash core
    output logic [31:0] W_o,
    output logic W_dv
);

    logic [5:0]  W_count;      // Counter 0-63
    logic [31:0] W_reg [0:15]; // Sliding window of 16 words
    logic [31:0] w_next;       // Combinatorial signal for the calculated W

   
    always_comb begin
        if (W_count < 16) begin
            
            w_next = M_i;
        end else begin
            w_next = sigma1(W_reg[14]) + W_reg[9] + sigma0(W_reg[1]) + W_reg[0];
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            W_count <= '0;
            W_o     <= '0;
            W_dv    <= 1'b0;
      
            for(int i=0; i<16; i++) W_reg[i] <= '0;
        end
        else begin
          
            if (W_count < 16) begin
                if (M_dv) begin
                    W_reg[W_count] <= w_next; // Store input in the correct slot
                    W_o            <= w_next; // Output immediately
                    W_dv           <= 1'b1;
                    W_count        <= W_count + 1;
                end
                else begin
                    W_dv <= 1'b0; // Pause if input data is invalid
                end
            end
            
            else if (W_count < 64) begin
                // Shift Logic: Move everything down by 1
                for (int i = 0; i < 15; i++) begin
                    W_reg[i] <= W_reg[i+1];
                end
                
                // Load the NEW calculated value into the top of the buffer
                W_reg[15] <= w_next;
                W_o       <= w_next;
                W_dv      <= 1'b1;

                // Termination
                if (W_count == 63) begin
                    W_count <= '0; // Reset for next block
                end else begin
                    W_count <= W_count + 1;
                end
            end
        end
    end

endmodule
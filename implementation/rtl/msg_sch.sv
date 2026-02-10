//msg_sch
// Company: 
// Engineer: Shravani and Nisarg
// 
// Create Date: 27.01.2026 17:47:00
// Design Name: 
// Module Name: message_scheduler
// Project Name: SHA - 256
// Target Devices: 
// Tool Versions: 
// Description: 
//takes M0-M15 and converts it to W0-W63
// 
// Dependencies: sha_functions.svh
// 
// Revision: 
// Revision 0.01 - File Created
// Additional Comments:
// 

`timescale 1ns / 1ps
`include "sha_function.sv" 

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



function automatic [31:0] ROTR;
    input [31:0] x;
    input [4:0]  n;

    begin
            ROTR = (x >> n) | (x << (32-n));
    end
endfunction
    
function automatic [31:0] SHR;
    input [31:0] x;
    input [4:0]  n;

    begin
            SHR = x >> n;
    end
endfunction

function automatic [31:0] sigma0;
    input [31:0] x;

    begin
        sigma0 = ROTR(x,7) ^ ROTR(x,18) ^ SHR(x,3);
    end
endfunction


function automatic [31:0] sigma1;
    input [31:0] x;

    begin
        sigma1 = ROTR(x,17) ^ ROTR(x,19) ^ SHR(x,10);
    end
endfunction


endmodule

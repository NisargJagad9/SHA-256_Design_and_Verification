`timescale 1ns / 1ps
`include "sha_functions.svh"
//////////////////////////////////////////////////////////////////////////////////
// Created by : Nisarg and Shravani
// Create Date: 01/26/2026 08:55:02 PM
// Design Name: msg scheduler
// Module Name: msg_sch
// Project Name: SHA - 256
// Target Devices: -
// Tool Versions: -
// Description: 
// Takes M0-M15 and converts it to W0-W63
// 
// Dependencies: sha_functions.svh
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module msg_sch (
                    input  logic        clk,
                    input  logic        rst,
                    input  logic [31:0] M_i,
                    input  logic        M_dv,
                    output logic [31:0] W_o,
                    output logic        W_dv
);


logic [5:0] W_count;
logic [31:0] W_reg [0:15];

always_ff@(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        W_count <= 'b0;
        W_o <= 'b0;
        W_dv <= 'b0;
    end
    else if(M_dv && W_count < 16)
    begin
        W_reg[W_count] <= M_i;
        W_count++;
        W_o <= W_reg[W_count];
        W_dv <= 1'b1;
    end
    else if(W_count >= 16)
    begin
        
        for (integer i = 0; i < 15 ; i++ ) begin
            W_reg[i] <= W_reg[i+1];            
        end
        W_reg[15] <= W_o;
        W_o <= sigma1(W_reg[14]) + W_reg[9] + sigma0(W_reg[1]) + W_reg[0];

        if(W_count==63)
        begin
            W_count <= 'b0;
            W_dv <= 1'b1;
            W_o <= 'b0;
        end
    end
end

endmodule
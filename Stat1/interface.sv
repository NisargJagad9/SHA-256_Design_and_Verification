`timescale 1ns / 1ps

 interface hash_256(input logic clk,input logic rst_n);
    logic load_i;
    logic[31:0] Kt_i,Wt_i;
    logic[31:0] A_i, B_i, C_i, D_i, E_i, F_i, G_i, H_i;
    logic[31:0] A_o, B_o, C_o, D_o, E_o, F_o, G_o,H_o;
    logic[255:0]finall;
    logic done; 

endinterface


//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// Create Date: 27.01.2026 10:30:11
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Dependencies: 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
module top (
    input  logic        clk,
    input  logic        rst_n,

    // Message input interface (example: from UART / TB)
    input  logic        msg_valid,
    input  logic [5:0] byte_valid,
    input  logic [439:0] msg_word,

    // Final output
    output logic        hash_done,
    output logic [255:0] fin_hash,
    output logic  [6:0] round_idx_of
);

    // ------------------------------------------------------------
    // Internal signals
    // ------------------------------------------------------------

   // Preprocessor outputs
    logic        valid_o;      // Valid signal from preproc to msg_sch
    logic [31:0] M_o;          // 32-bit word from preproc to msg_sch
    
    // Message scheduler outputs  
    logic        W_dv;         // Valid signal from msg_sch to hash_core
    logic [31:0] W_o;          // 32-bit W word from msg_sch to hash_core
    
    // ------------------------------------------------------------
    // Padder & Parser
    // ------------------------------------------------------------
    preproc u_padder (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_valid     (msg_valid),
        .data_in        (msg_word),
        .byte_valid     (byte_valid),
        .valid_o        (valid_o),
        .M_o            (M_o)
    );

    // ------------------------------------------------------------
    // Message Scheduler
    // ------------------------------------------------------------
    msg_sch u_sched (
        .clk        (clk),
        .rst_n      (rst_n),
        .M_dv       (valid_o),
        .M_i        (M_o),
        .W_o        (W_o),
        .W_dv       (W_dv)
    );

    // ------------------------------------------------------------
    // Hash Core (Compression Function)
    // ------------------------------------------------------------
    hash_core u_hash (
        .clk            (clk),
        .rst_n          (rst_n),
        .d_valid        (W_dv),
       // .Kt_i           (Kt_i),
        .Wt_i           (W_o),
        .fin_hash       (fin_hash),
        .done           (hash_done),
        .round_idx_o    (round_idx_o)
    );
endmodule
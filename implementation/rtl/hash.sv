
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
module hash (
    input  logic        clk,
    input  logic        rst_n,

 // UART-like interface
    input  logic       rx_valid,        // new byte is available
    input  logic [7:0] rx_data,   

    // Final output
    output logic        hash_done,
    output logic [255:0] fin_hash
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
        .rx_valid     (rx_valid),
        .rx_data        (rx_data),
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
        .Wt_i           (W_o),
        .fin_hash       (fin_hash),
        .done           (hash_done)
    );
endmodule
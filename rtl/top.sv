`timescale 1ns / 1ps

`timescale 1ns / 1ps
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


module top (
    input  logic        clk,
    input  logic        rst_n,

    // Message input interface (example: from UART / TB)
    input  logic        msg_valid,
    input  logic [31:0] msg_word,

    // Final output
    output logic        hash_done,
    output logic [255:0] fin_hash
);

    // ------------------------------------------------------------
    // Internal signals
    // ------------------------------------------------------------

    // Padder / parser
    logic        block_valid;
    logic [511:0] block_512;

    // Controller
    logic        d_valid;
    logic        sched_en;
    logic [5:0]  round_idx;

    // Scheduler / ROM outputs
    logic [31:0] Wt_i;
    logic [31:0] Kt_i;

    // ------------------------------------------------------------
    // Padder & Parser
    // ------------------------------------------------------------
    preproc u_padder (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_valid     (data_valid),
        .data_in        (data_in),
        .byte_valid     (byte_valid),
        .valid_o        (valid_o),
        .M_o            (M_o)
    );

    // ------------------------------------------------------------
    // Controller FSM
    // ------------------------------------------------------------
//    sha256_controller u_ctrl (
//        .clk             (clk),
//        .rst_n           (rst_n),
//        .msg_block_valid (valid_o),
//        .d_valid         (d_valid),
//        .sched_en        (sched_en),
//        .round_idx       (round_idx),
//        .hash_done       (hash_done)
//    );

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
    // SHA-256 K constant ROM
    // ------------------------------------------------------------
//    sha256_k_rom u_krom (
//        .clk(clk),
//        .addr (round_idx),
//        .Kt_i (Kt_i)
//    );

    // ------------------------------------------------------------
    // Hash Core (Compression Function)
    // ------------------------------------------------------------
    hash_core u_hash (
        .clk            (clk),
        .rst_n          (rst_n),
        .d_valid        (d_valid),
        .d_valid        (W_dv),
        .Kt_i           (Kt_i),
        .Wt_i           (W_o),
        .fin_hash       (fin_hash),
        .done           (hash_done),
        .round_idx_o    (round_idx_o)
    );

endmodule

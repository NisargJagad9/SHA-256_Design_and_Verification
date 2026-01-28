`include timescale 1ns/1ps
module sha256_top (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         start,
    input  logic         data_valid,
    input  logic [127:0] data_in,
    input  logic [3:0]   byte_valid,

    output logic [255:0] hash,
    output logic         done
);

    // ---------------------------------------
    // Internal signals
    // ---------------------------------------

    // Preprocessor → message schedule
    logic        msg_valid;
    logic [31:0] M_word;

    // Message schedule → hashcore
    logic [31:0] Wt;

    // Controller signals
    logic msg_ld;
    logic hash_ld;
    logic hash_en;
    logic final_flag;
    logic done_ctrl;
    logic [5:0] round;

    // ROM
    logic [31:0] Kt;
    logic [31:0] H_init [0:7];

    // Hashcore I/O
    logic [31:0] A_o,B_o,C_o,D_o,E_o,F_o,G_o,H_o;
    logic [255:0] final_hash;

    // ---------------------------------------
    // Preprocessor
    // ---------------------------------------
    preprocessor u_pre (
        .clk        (clk),
        .rst        (~rst_n),
        .data_valid (data_valid),
        .data_in    (data_in),
        .byte_valid (byte_valid),
        .valid_o    (msg_valid),
        .M_o        (M_word)
    );

    // ---------------------------------------
    // Message Scheduler
    // ---------------------------------------
    sha256_msg_sched u_sched (
        .clk   (clk),
        .rst_n (rst_n),
        .ld_i  (msg_ld),
        .M_i   (M_word),
        .Wt_o  (Wt)
    );

    // ---------------------------------------
    // Controller FSM
    // ---------------------------------------
    sha256_ctrl_fsm u_ctrl (
        .clk               (clk),
        .rst_n             (rst_n),
        .start_i           (start),
        .msg_word_valid_i  (msg_valid),

        .msg_ld_o          (msg_ld),
        .hash_ld_o         (hash_ld),
        .hash_en_o         (hash_en),
        .final_o           (final_flag),
        .done_o            (done_ctrl),

        .round_o           (round)
    );

    // ---------------------------------------
    // ROM for K and H
    // ---------------------------------------
    sha256_rom u_rom (
        .clk     (clk),
        .addr    ({1'b0, round}),
        .dataout (Kt)
    );

    // Initial hash values (H0-H7)
    sha256_rom u_rom_h0 (.clk(clk), .addr(7'd64), .dataout(H_init[0]));
    sha256_rom u_rom_h1 (.clk(clk), .addr(7'd65), .dataout(H_init[1]));
    sha256_rom u_rom_h2 (.clk(clk), .addr(7'd66), .dataout(H_init[2]));
    sha256_rom u_rom_h3 (.clk(clk), .addr(7'd67), .dataout(H_init[3]));
    sha256_rom u_rom_h4 (.clk(clk), .addr(7'd68), .dataout(H_init[4]));
    sha256_rom u_rom_h5 (.clk(clk), .addr(7'd69), .dataout(H_init[5]));
    sha256_rom u_rom_h6 (.clk(clk), .addr(7'd70), .dataout(H_init[6]));
    sha256_rom u_rom_h7 (.clk(clk), .addr(7'd71), .dataout(H_init[7]));

    // ---------------------------------------
    // Hashcore
    // ---------------------------------------
    hashcore u_hash (
        .clk    (clk),
        .rst_n  (rst_n),
        .load   (hash_ld),

        .Kt_i   (Kt),
        .Wt_i   (Wt),

        .A_i (H_init[0]),
        .B_i (H_init[1]),
        .C_i (H_init[2]),
        .D_i (H_init[3]),
        .E_i (H_init[4]),
        .F_i (H_init[5]),
        .G_i (H_init[6]),
        .H_i (H_init[7]),

        .A_o (),
        .B_o (),
        .C_o (),
        .D_o (),
        .E_o (),
        .F_o (),
        .G_o (),
        .H_o (),
        .finall (final_hash),
        .done   ()
    );

    assign hash = final_hash;
    assign done = done_ctrl;

endmodule

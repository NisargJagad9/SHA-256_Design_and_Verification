`timescale 1ns / 1ps

module top (
    input  logic  clk,
    input  logic  rst,
    input  logic  uart_rx,
    output logic  uart_tx
);

    // ────────────────────────────────────────────────
    // UART RX
    // ────────────────────────────────────────────────
    logic       rx_dv;
    logic [7:0] rx_byte;
    logic rst_n = ~rst;

    uart_rx #(
        .CLKS_PER_BIT(10416)           // adjust for your clock & baudrate
    ) u_uart_rx (
        .i_Clock     (clk),
        .i_Rx_Serial (uart_rx),
        .o_Rx_DV     (rx_dv),
        .o_Rx_Byte   (rx_byte)
    );

    // ────────────────────────────────────────────────
    // Preprocessor / Padder → produces 32-bit words + valid
    // ────────────────────────────────────────────────
    logic       pre_valid;
    logic [31:0] pre_word;

    preproc u_preproc (
        .clk        (clk),
        .rst_n      (rst_n),
        .rx_valid   (rx_dv),
        .rx_data    (rx_byte),
        .valid_o    (pre_valid),
        .M_o        (pre_word)
    );

    // ────────────────────────────────────────────────
    // Message Scheduler → W0..W63
    // ────────────────────────────────────────────────
    logic       W_valid;
    logic [31:0] W_word;

    msg_sch u_msg_sch (
        .clk     (clk),
        .rst_n   (rst_n),
        .M_dv    (pre_valid),
        .M_i     (pre_word),
        .W_o     (W_word),
        .W_dv    (W_valid)
    );

    // ────────────────────────────────────────────────
    // Hash core (compression function)
    // ────────────────────────────────────────────────
    logic       hash_done;
    logic [255:0] final_hash;

    hash_core u_hash_core (
        .clk        (clk),
        .rst_n      (rst_n),
        .d_valid    (W_valid),
        .Wt_i       (W_word),
        .fin_hash   (final_hash),
        .done       (hash_done)
    );

    // ────────────────────────────────────────────────
    // Parallel-In Serial-Out → byte stream for UART TX
    // ────────────────────────────────────────────────
    logic       tx_start_pulse;
    logic       tx_dv;
    logic [7:0] tx_byte;
    logic       tx_active;
    logic       tx_done;

    // Generate one-cycle start pulse when hash is ready
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tx_start_pulse <= 1'b0;
        else
            tx_start_pulse <= hash_done && !tx_start_pulse;   // single cycle
    end

    piso u_piso (
        .clk        (clk),
        .rst_n      (rst_n),
        .hash_done  (tx_start_pulse),
        .fin_hash   (final_hash),
        .tx_dv      (tx_dv),
        .tx_byte    (tx_byte),
        .tx_done    (tx_done),
        .tx_active  (tx_active)
    );

    // ────────────────────────────────────────────────
    // UART TX
    // ────────────────────────────────────────────────
    uart_tx #(
        .CLKS_PER_BIT(10416)           // same setting as RX
    ) u_uart_tx (
        .i_Clock     (clk),
        .i_Tx_DV     (tx_dv),
        .i_Tx_Byte   (tx_byte),
        .o_Tx_Active (tx_active),
        .o_Tx_Serial (uart_tx),
        .o_Tx_Done   (tx_done)
    );

    // ────────────────────────────────────────────────
    // Optional ILA / debug connection
    // ────────────────────────────────────────────────
     ila_0 your_ila (
         .clk        (clk),
         .probe0     (final_hash),
         .probe1     (hash_done),
         .probe2     (rx_dv),
         .probe3     (rx_byte),
         .probe4     (pre_valid),
         .probe5     (W_valid),
         .probe6     (tx_dv)
     );

endmodule
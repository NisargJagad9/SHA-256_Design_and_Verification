// ============================================================================
// SHA-256 Hash Core Logic
//  - Single-cycle combinational round
//  - Registers a..h
//  - Implements Σ0, Σ1, Maj, Ch
//  - Optimized for minimal registers (ASIC style)
// ============================================================================

`timescale 1ns / 1ps

// Corrected SHA-256 Hash Core Module
module hash_core(
    input logic clk,
    input logic rst_n,
    input bit load_i,
    
    // Running constants and msg schedule ip
    input logic [31:0] Kt_i,        // constant 0-63
    input logic [31:0] Wt_i,        // message scheduling
    
    // Initial hash values 
    input logic [31:0] A_i, B_i, C_i, D_i, E_i, F_i, G_i, H_i,
    
    // outputs
    output logic [31:0] A_o, B_o, C_o, D_o, E_o, F_o, G_o, H_o,
    output logic [255:0] finall
);

logic [31:0] a, b, c, d, e, f, g, h;   // working registers
logic [5:0] round_cnt;                 // 6-bit counter for 64 rounds (0-63)
logic compute_done;                    // rounds complete flag

typedef enum logic [1:0] {
    IDLE = 2'b00,
    COMPUTE = 2'b01,
    DONE = 2'b10
} state_t;

state_t state, next_state;

// ROTR functions
function automatic logic [31:0] rotr2(input logic [31:0] x);
    return {x[1:0], x[31:2]};
endfunction

function automatic logic [31:0] rotr6(input logic [31:0] x);
    return {x[5:0], x[31:6]};
endfunction

function automatic logic [31:0] rotr11(input logic [31:0] x);
    return {x[10:0], x[31:11]};
endfunction

function automatic logic [31:0] rotr13(input logic [31:0] x);
    return {x[12:0], x[31:13]};
endfunction

function automatic logic [31:0] rotr22(input logic [31:0] x);
    return {x[21:0], x[31:22]};
endfunction

function automatic logic [31:0] rotr25(input logic [31:0] x);
    return {x[24:0], x[31:25]};
endfunction

// **FIX 1: Combinational temps computed from sequential regs**
logic [31:0] sigma_0_a, sigma_1_e, Maj, Ch, T1_temp, T2_temp;
assign sigma_1_e = rotr6(e) ^ rotr11(e) ^ rotr25(e);
assign sigma_0_a = rotr2(a) ^ rotr13(a) ^ rotr22(a);
assign Maj = (a & b) ^ (a & c) ^ (b & c);
assign Ch = (e & f) ^ (~e & g);
assign T1_temp = h + sigma_1_e + Ch + Kt_i + Wt_i;
assign T2_temp = sigma_0_a + Maj;

// State machine - sequential
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        round_cnt <= 6'd0;
        compute_done <= 1'b0;
    end else begin
        state <= next_state;
        case (state)
            IDLE: begin
                round_cnt <= 6'd0;
                compute_done <= 1'b0;
            end
            COMPUTE: begin
                if (compute_done) begin
                    // Stay in COMPUTE until load_i
                end else if (round_cnt == 6'd63) begin
                    compute_done <= 1'b1;  // **FIX 2: Check BEFORE increment**
                end else begin
                    round_cnt <= round_cnt + 1;
                end
            end
        endcase
    end
end

// Next state logic
always_comb begin
    next_state = state;
    case (state)
        IDLE:    if (load_i) next_state = COMPUTE;
        COMPUTE: if (compute_done) next_state = DONE;
        DONE:    next_state = IDLE;
    endcase
end

// **FIX 3: Corrected datapath - all values from PREVIOUS cycle**
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a <= 32'h0; b <= 32'h0; c <= 32'h0; d <= 32'h0;
        e <= 32'h0; f <= 32'h0; g <= 32'h0; h <= 32'h0;
    end else if (state == IDLE && load_i) begin
        // Load initial hash values on rising edge after load_i
        a <= A_i; b <= B_i; c <= C_i; d <= D_i;
        e <= E_i; f <= F_i; g <= G_i; h <= H_i;
    end else if (state == COMPUTE && !compute_done) begin
        // SHA-256 compression function - ALL from previous values
        h <= g;
        g <= f;
        f <= e;
        e <= d + T1_temp;
        d <= c;
        c <= b;
        b <= a;
        a <= T1_temp + T2_temp;
    end
end

// Final hash outputs (working vars + initial hash values)
assign A_o = A_i + a;
assign B_o = B_i + b;
assign C_o = C_i + c;
assign D_o = D_i + d;
assign E_o = E_i + e;
assign F_o = F_i + f;
assign G_o = G_i + g;
assign H_o = H_i + h;

assign finall = {A_o, B_o, C_o, D_o, E_o, F_o, G_o, H_o};

endmodule


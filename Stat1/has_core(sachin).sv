`timescale 1ns / 1ps

module hash_core(
    input  logic clk,
    input  logic rst_n,
    input  bit   load_i,       // start signal
    
    // Inputs for this round
    input  logic [31:0] Kt_i,  // round constant
    input  logic [31:0] Wt_i,  // message schedule word
    
    // Initial hash values
    input  logic [31:0] A_i, B_i, C_i, D_i, E_i, F_i, G_i, H_i,
    
    // Outputs
    output logic [31:0] A_o, B_o, C_o, D_o, E_o, F_o, G_o, H_o,
    output logic [255:0] finall,
    output logic done          // flag when all 64 rounds complete
);


// registers

logic [31:0] a, b, c, d, e, f, g, h;
logic [5:0]  round_cnt;  // counts 0..63


// rotate function

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


// SHA-256 functions

logic [31:0] sigma_0_a, sigma_1_e, Maj, Ch, T1, T2;

assign sigma_1_e = rotr6(e) ^ rotr11(e) ^ rotr25(e);
assign sigma_0_a = rotr2(a) ^ rotr13(a) ^ rotr22(a);
assign Maj       = (a & b) ^ (a & c) ^ (b & c);
assign Ch        = (e & f) ^ (~e & g);

assign T1 = h + sigma_1_e + Ch + Kt_i + Wt_i;
assign T2 = sigma_0_a + Maj;


// Sequential logic: counter + datapath

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a <= 0; b <= 0; c <= 0; d <= 0;
        e <= 0; f <= 0; g <= 0; h <= 0;
        round_cnt <= 0;
        done <= 0;
    end else if (load_i) begin
        // Load initial values
        a <= A_i; b <= B_i; c <= C_i; d <= D_i;
        e <= E_i; f <= F_i; g <= G_i; h <= H_i;
        round_cnt <= 0;
        done <= 0;
    end else if (!done) begin
        // Perform one round
        h <= g;
        g <= f;
        f <= e;
        e <= d + T1;
        d <= c;
        c <= b;
        b <= a;
        a <= T1 + T2;

        // Update counter
        if (round_cnt == 6'd63) begin
            done <= 1; //  if all rounds  are finished 
        end else begin
            round_cnt <= round_cnt + 1;
        end
    end
end


// Final outputs (add working vars to initial values)
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

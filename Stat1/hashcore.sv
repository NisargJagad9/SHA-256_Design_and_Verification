// ============================================================================
// SHA-256 Hash Core Logic
//  - Single-cycle combinational round
//  - Registers a..h
//  - Implements Σ0, Σ1, Maj, Ch
//  - Optimized for minimal registers (ASIC style)
// ============================================================================

// `timescale 1ns / 1ps

// // Corrected SHA-256 Hash Core Module
// module hash_core(
//     input logic clk,
//     input logic rst_n,
//     input bit load_i,
    
//     // Running constants and msg schedule ip
//     input logic [31:0] Kt_i,        // constant 0-63
//     input logic [31:0] Wt_i,        // message scheduling
    
//     // Initial hash values 
//     input logic [31:0] A_i, B_i, C_i, D_i, E_i, F_i, G_i, H_i,
    
//     // outputs
//     output logic [31:0] A_o, B_o, C_o, D_o, E_o, F_o, G_o, H_o,
//     output logic [255:0] finall
// );

// logic [31:0] a, b, c, d, e, f, g, h;   // working registers
// logic [5:0] round_cnt;                 // 6-bit counter for 64 rounds (0-63)
// logic compute_done;                    // rounds complete flag

// typedef enum logic [1:0] {
//     IDLE = 2'b00,
//     COMPUTE = 2'b01,
//     DONE = 2'b10
// } state_t;

// state_t state, next_state;

// // ROTR functions
// function automatic logic [31:0] rotr2(input logic [31:0] x);
//     return {x[1:0], x[31:2]};
// endfunction

// function automatic logic [31:0] rotr6(input logic [31:0] x);
//     return {x[5:0], x[31:6]};
// endfunction

// function automatic logic [31:0] rotr11(input logic [31:0] x);
//     return {x[10:0], x[31:11]};
// endfunction

// function automatic logic [31:0] rotr13(input logic [31:0] x);
//     return {x[12:0], x[31:13]};
// endfunction

// function automatic logic [31:0] rotr22(input logic [31:0] x);
//     return {x[21:0], x[31:22]};
// endfunction

// function automatic logic [31:0] rotr25(input logic [31:0] x);
//     return {x[24:0], x[31:25]};
// endfunction

// // **FIX 1: Combinational temps computed from sequential regs**
// logic [31:0] sigma_0_a, sigma_1_e, Maj, Ch, T1_temp, T2_temp;
// assign sigma_1_e = rotr6(e) ^ rotr11(e) ^ rotr25(e);
// assign sigma_0_a = rotr2(a) ^ rotr13(a) ^ rotr22(a);
// assign Maj = (a & b) ^ (a & c) ^ (b & c);
// assign Ch = (e & f) ^ (~e & g);
// assign T1_temp = h + sigma_1_e + Ch + Kt_i + Wt_i;
// assign T2_temp = sigma_0_a + Maj;

// // State machine - sequential
// always_ff @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         state <= IDLE;
//         round_cnt <= 6'd0;
//         compute_done <= 1'b0;
//     end else begin
//         state <= next_state;
//         case (state)
//             IDLE: begin
//                 round_cnt <= 6'd0;
//                 compute_done <= 1'b0;
//             end
//             COMPUTE: begin
//                 if (compute_done) begin
//                     // Stay in COMPUTE until load_i
//                 end else if (round_cnt == 6'd63) begin
//                     compute_done <= 1'b1;  // **FIX 2: Check BEFORE increment**
//                 end else begin
//                     round_cnt <= round_cnt + 1;
//                 end
//             end
//         endcase
//     end
// end

// // Next state logic
// always_comb begin
//     next_state = state;
//     case (state)
//         IDLE:    if (load_i) next_state = COMPUTE;
//         COMPUTE: if (compute_done) next_state = DONE;
//         DONE:    next_state = IDLE;
//     endcase
// end

// // **FIX 3: Corrected datapath - all values from PREVIOUS cycle**
// always_ff @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         a <= 32'h0; b <= 32'h0; c <= 32'h0; d <= 32'h0;
//         e <= 32'h0; f <= 32'h0; g <= 32'h0; h <= 32'h0;
//     end else if (state == IDLE && load_i) begin
//         // Load initial hash values on rising edge after load_i
//         a <= A_i; b <= B_i; c <= C_i; d <= D_i;
//         e <= E_i; f <= F_i; g <= G_i; h <= H_i;
//     end else if (state == COMPUTE && !compute_done) begin
//         // SHA-256 compression function - ALL from previous values
//         h <= g;
//         g <= f;
//         f <= e;
//         e <= d + T1_temp;
//         d <= c;
//         c <= b;
//         b <= a;
//         a <= T1_temp + T2_temp;
//     end
// end

// // Final hash outputs (working vars + initial hash values)
// assign A_o = A_i + a;
// assign B_o = B_i + b;
// assign C_o = C_i + c;
// assign D_o = D_i + d;
// assign E_o = E_i + e;
// assign F_o = F_i + f;
// assign G_o = G_i + g;
// assign H_o = H_i + h;

// assign finall = {A_o, B_o, C_o, D_o, E_o, F_o, G_o, H_o};

// endmodule




//Current:
`timescale 1ns / 1ps

module hash_core(
    input logic clk,
    input logic rst_n,
    input bit d_valid,
    
    //Msg scheduler op
    input logic [31:0] Kt_i,      //SHA constant for the current round  from ROM module
    input logic [31:0] Wt_i,      //32 bit word from msg scheduler  
    
    //output: 8 working variable registers (each of 32 bits) that hold hash state
    output logic [255:0] fin_hash
);
//logic compute_done;   
//intermediate hash state registers
    logic [31:0] H0, H1, H2, H3, H4, H5, H6, H7;
//working variables
    logic [31:0] A_o, B_o, C_o, D_o, E_o, F_o, G_o, H_o
logic [7:0] count;

      //combinational functions
logic [31:0] T1, T2;
logic [31:0] sigma_0, sigma_1, Maj, Ch;

// ROTR function
function automatic logic [31:0] rotr(input logic [31:0] x, input int n);
   rotr = (x>>n) | (x << (32-n));
endfunction

// ROM Address Logic
    // If resetting, we could theoretically pull H values, but usually, 
    // internal registers are hardcoded or loaded once. 
    // For this design, we use counter_iteration to get K values.
    //assign rom_addr = counter_iteration;
    
    //ROM instantiation
   // ROM constants_inst (.clk(clk), .addr(rom_addr), data(Kt_i));

always_comb
         begin
            sigma_1 = rotr(E_o,6) ^ rotr(E_o,11) ^ rotr(E_o,25);
            sigma_0 = rotr(A_o,2) ^ rotr(A_o,13) ^ rotr(A_o,22);
             
            Maj = (A_o & B_o) ^ (A_o & C_o) ^ (B_o & C_o);
            Ch = (E_o & F_o) ^ ((~ E_o) & G_o);
             
            T1 = H_o + sigma_1 + Ch + Kt_i + Wt_i;
            T2 = sigma_0 + Maj;
         end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        begin
                //reset count to 0
                count <= 7'd0;
            
                //Put initial hash values
                H0 <= 32'h6a09e667;
                H1 <= 32'hbb67ae85;
                H2 <= 32'h3c6ef372;
                H3 <= 32'ha54ff53a;
                H4 <= 32'h510e527f;
                H5 <= 32'h9b05688c;
                H6 <= 32'h1f83d9ab;
                H7 <= 32'h5be0cd19;

            //clean working vars
                A_o <= 32'b0;
                B_o <= 32'b0;
                C_o <= 32'b0;
                D_o <= 32'b0;
                E_o <= 32'b0;
                F_o <= 32'b0;
                G_o <= 32'b0;
                H_o <= 32'b0;
        end
        
    else 
        begin    
            if(d_valid == 1)
                 begin
                    count <= 7'b0;

                     //put initial hash values in working vars and start hashing
                    A_o   <= H0;
                    B_o   <= H1;
                    C_o   <= H2;
                    D_o   <= H3;
                    E_o   <= H4;
                    F_o   <= H5;
                    G_o   <= H6;
                    H_o   <= H7;
                 end
            
            else if (count < 7'd64) 
                begin
                    A_o <= T1 + T2;
                    B_o <= A_o;
                    C_o <= B_o;
                    D_o <= C_o;
                    E_o <= D_o + T1;
                    F_o <= E_o;
                    G_o <= F_o;
                    H_o <= G_o;                
                    count <= count + 1'b1;
                end      

            else if (count == 7'd64)
                begin 
               H0 <= H0 + A_o;
                H1 <= H1 + B_o;
                H2 <= H2 + C_o;
                H3 <= H3 + D_o;
                H4 <= H4 + E_o;
                H5 <= H5 + F_o;
                H6 <= H6 + G_o;
                H7 <= H7 + H_o;

                count <= count + 1'b1;
        end
   end
end
    //finaal op
    assign fin_hash = {H0, H1, H2, H3, H4, H5, H6, H7};
endmodule







//Trial 2:
// `timescale 1ns / 1ps

// module iterative_processing(
//     input  logic        clk,
//     input  logic        rst_n,
//     input  logic        padding_done,
//     input  logic [31:0] w,
//     output logic [255:0] final_hash, // The full 256-bit result
//     output logic         done_pulse  // High for one cycle when hash is ready
// );

//     logic [6:0]  round_count;
//     logic [31:0] k_from_rom;
//     logic [31:0] s0, s1, ch, maj, t1, t2;
//     logic        busy;

//     // Registers to hold the values at the START of the 64 rounds
//     logic [31:0] h0_init, h1_init, h2_init, h3_init, h4_init, h5_init, h6_init, h7_init;
    
//     // Working registers (a-h)
//     logic [31:0] a, b, c, d, e, f, g, h;

//     // ROTR function
//     function automatic logic [31:0] rotr(input logic [31:0] x, input int n);
//         rotr = (x >> n) | (x << (32 - n));
//     endfunction

//     sha256_rom constants_inst (.clk(clk), .addr(round_count), .dataout(k_from_rom));

//     // Combinational logic for the round
//     always_comb begin
//         s0  = rotr(a, 2)  ^ rotr(a, 13) ^ rotr(a, 22);
//         s1  = rotr(e, 6)  ^ rotr(e, 11) ^ rotr(e, 25);
//         maj = (a & b) ^ (a & c) ^ (b & c);
//         ch  = (e & f) ^ (~e & g);
//         t1  = h + s1 + ch + k_from_rom + w;
//         t2  = s0 + maj;
//     end

//     always_ff @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             busy <= 1'b0;
//             round_count <= 0;
//             done_pulse  <= 1'b0;
//             // Load initial constants
//             {a, b, c, d, e, f, g, h} <= {32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a, 
//                                          32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19};
//         end else begin
//             done_pulse <= 1'b0; // Default state
            
//             if (!busy && padding_done) begin
//                 busy <= 1'b1;
//                 round_count <= 0;
//                 // Capture the "Start" values to add later
//                 {h0_init, h1_init, h2_init, h3_init, h4_init, h5_init, h6_init, h7_init} <= {a, b, c, d, e, f, g, h};
//             end 
//             else if (busy) begin
//                 if (round_count < 64) begin
//                     a <= t1 + t2;
//                     b <= a;
//                     c <= b;
//                     d <= c;
//                     e <= d + t1;
//                     f <= e;
//                     g <= f;
//                     h <= g;
//                     round_count <= round_count + 1;
//                 end 
//                 else begin
//                     // ROUNDS FINISHED: Perform the final addition
//                     a <= a + h0_init;
//                     b <= b + h1_init;
//                     c <= c + h2_init;
//                     d <= d + h3_init;
//                     e <= e + h4_init;
//                     f <= f + h5_init;
//                     g <= g + h6_init;
//                     h <= h + h7_init;
                    
//                     busy <= 1'b0;
//                     done_pulse <= 1'b1;
//                 end
//             end
//         end
//     end

//     // Concatenate all 8 registers into the final 256-bit output
//     assign final_hash = {a, b, c, d, e, f, g, h};

// endmodule

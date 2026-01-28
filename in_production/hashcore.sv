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
    //input bit load_i,
    
    //Msg scheduler op
    input logic [31:0] Kt_i,      //SHA constant for the current round  from ROM module
    input logic [31:0] Wt_i,      //32 bit word from msg scheduler  
    
    //output: 8 working variable registers (each of 32 bits) that hold hash state
    output logic [255:0] fin_hash,
    output logic done,          // flag when all 64 rounds complete
    output logic [6:0] round_idx_o // Output for Testbench Sync
);
//logic compute_done;   
//intermediate hash state registers
    logic [31:0] H0, H1, H2, H3, H4, H5, H6, H7;
//working variables
  logic [31:0] a, b, c, d, e, f, g, h;
  //registers holding final output values
  logic [31:0] A_o, B_o, C_o, D_o, E_o, F_o, G_o, H_o;
  //count var
  logic [6:0] count;
 
  //ROM values array
  const logic [31:0] ROM [0:63] ='{
        32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5,
        32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
        32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3,
        32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
        32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc,
        32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,
        32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7,
        32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,
        32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13,
        32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,
        32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3,
        32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,
        32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5,
        32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,
        32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208,
        32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2
        };
        
        assign Kt_i = ROM[count];

      //combinational functions
//logic [31:0] T1, T2;
//logic [31:0] sigma_0, sigma_1, Maj, Ch;

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
    //sha256_k_rom constants_inst (.clk(clk), .addr(rom_addr), dataout(Kt_i));

//always_comb
//         begin
//            sigma_1 = rotr(E_o,6) ^ rotr(E_o,11) ^ rotr(E_o,25);
//            sigma_0 = rotr(A_o,2) ^ rotr(A_o,13) ^ rotr(A_o,22);
             
//            Maj = (A_o & B_o) ^ (A_o & C_o) ^ (B_o & C_o);
//            Ch = (E_o & F_o) ^ ((~ E_o) & G_o);
             
         
//         end
         
         
function automatic logic [31:0] Ch(input logic [31:0] x, y, z);
    Ch = (x & y) ^ (~x & z);
endfunction
    
function automatic logic [31:0] Maj(input logic [31:0] x, y, z);
    Maj = (x & y)^(x & z)^(y & z);
endfunction

function automatic logic [31:0] sigma_0(input logic [31:0] x);
    sigma_0 = rotr(x,2) ^ rotr(x,13) ^ rotr(x,22);
endfunction

function automatic logic [31:0] sigma_1(input logic [31:0] x);
    sigma_1 = rotr(x,6) ^ rotr(x,11) ^ rotr(x,25);
endfunction

   assign T1 = h + sigma_1(e) + Ch(e,f,g) + Kt_i + Wt_i;
   assign T2 = sigma_0(a) + Maj(a,b,c);




always_ff @(posedge clk)
 begin
    if (!rst_n) 
        begin
                //reset count to 0
                count <= 7'd0;
                done <= 1'b0;
            
                //Put initial hash values
                H0 <= 32'd0;
                H1 <= 32'd0;
                H2 <= 32'd0;
                H3 <= 32'd0;
                H4 <= 32'd0;
                H5 <= 32'd0;
                H6 <= 32'd0;
                H7 <= 32'd0;

            //clean working vars
                a <= 32'd0;
                b <= 32'd0;
                c <= 32'd0;
                d <= 32'd0;
                e <= 32'd0;
                f <= 32'd0;
                g <= 32'd0;
                h <= 32'd0;
                
                //ROM values for Kt_i
       
                
        end
        
    else 
        begin    
            if(d_valid == 1)
                 begin
                    count <= 7'b0;
                    done <= 1'b0;

                     //put initial hash values in working vars and start hashing
                    a <= 32'h6a09e667;
                    b <= 32'hbb67ae85; 
                    c <= 32'h3c6ef372; 
                    d <= 32'ha54ff53a;
                    e <= 32'h510e527f; 
                    f <= 32'h9b05688c; 
                    g <= 32'h1f83d9ab; 
                    h <= 32'h5be0cd19;
                    
                    H0 <= 32'h6a09e667;
                    H1 <= 32'hbb67ae85; 
                    H2 <= 32'h3c6ef372; 
                    H3 <= 32'ha54ff53a;
                    H4 <= 32'h510e527f; 
                    H5 <= 32'h9b05688c; 
                    H6 <= 32'h1f83d9ab; 
                    H7 <= 32'h5be0cd19;
                    
                 end
            
            else if (!done) 
                begin
                    h <= g;
                    g <= f;
                    f <= e; 
                    d <= c;
                    c <= b;
                    b <= a;
                    e <= d + T1;
                    a <= T1 + T2;     
                    
                    //increment count value       
                    count <= count + 1'b1;
                    
                    if(count == 63)
                        done <= 1'b1;
                end      
            end
        end

    assign round_idx_o = count;
    
    //use the CAPTURED start values, not the live input ports
    assign A_o = a + H0;
    assign B_o = b + H1;
    assign C_o = c + H2;
    assign D_o = d + H3;
    assign E_o = e + H4;
    assign F_o = f + H5;
    assign G_o = g + H6;
    assign H_o = h + H7;
    
               
    //finaal op
    assign fin_hash = {A_o,B_o,C_o,D_o,E_o,F_o,G_o,H_o};

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

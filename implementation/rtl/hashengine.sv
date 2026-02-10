//hash core - CORRECTED VERSION
`timescale 1ns / 1ps

module hash_core(
    input logic clk,
    input logic rst_n,
    input bit d_valid,
    
    //Msg scheduler op
    input logic [31:0] Wt_i,      //32 bit word from msg scheduler  
    
    //output: 8 working variable registers (each of 32 bits) that hold hash state
    output logic [255:0] fin_hash,
    output logic done         // flag when all 64 rounds complete
);

//intermediate hash state registers
    logic [31:0] H0, H1, H2, H3, H4, H5, H6, H7;
//working variables
  logic [31:0] a, b, c, d, e, f, g, h;
  //registers holding final output values
  logic [31:0] A_o, B_o, C_o, D_o, E_o, F_o, G_o, H_o;
  //count var
  logic [6:0] count;
  //internal wire
  logic [31:0] Kt_i;
  
  logic [31:0] T1, T2;
 
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

// ROTR function
function automatic logic [31:0] rotr(input logic [31:0] x, input int n);
   rotr = (x>>n) | (x << (32-n));
endfunction

         
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

   assign  T1 = h + sigma_1(e) + Ch(e,f,g) + Kt_i + Wt_i;
   assign  T2 = sigma_0(a) + Maj(a,b,c);




always_ff @(posedge clk or negedge rst_n)
 begin
    if (!rst_n) 
        begin
                //reset count to 0
                count <= 7'd0;
                done <= 1'b0;
            
                //Put initial hash values
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
        
    else 
        begin    
            // MAJOR FIX: Only process when d_valid is high AND we haven't completed 64 rounds
            if(d_valid == 1'b1 && count < 64)
                 begin
                    // Perform the round computation
                    h <= g;
                    g <= f;
                    f <= e; 
                    d <= c;
                    c <= b;
                    b <= a;
                    e <= d + T1;
                    a <= T1 + T2;
                    
                    // Increment counter
                    count <= count + 1'b1;
                    
                    // Set done flag when reaching round 63 (will be 64 next cycle)
                    if (count == 7'd63) begin
                        done <= 1'b1;
                        count <= 7'd0;
                    end else begin
                        done <= 1'b0;
                    end
                 end
            else if (count >= 64) begin
                // Stay in done state, wait for reset or new block
                done <= 1'b1;
            end
            else begin
                // No valid data, maintain current state
                done <= 1'b0;
            end
        end
end

     
    
    //use the CAPTURED start values, not the live input ports
    assign A_o = a + H0;
    assign B_o = b + H1;
    assign C_o = c + H2;
    assign D_o = d + H3;
    assign E_o = e + H4;
    assign F_o = f + H5;
    assign G_o = g + H6;
    assign H_o = h + H7;
    
               
    //final op
    assign fin_hash = {A_o,B_o,C_o,D_o,E_o,F_o,G_o,H_o};

endmodule
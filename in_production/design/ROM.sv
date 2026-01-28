`timescale 1ns / 1ps

module sha256_rom( 
    input logic clk,
    input logic [6:0] addr,
    output logic [31:0] dataout
    );
    
  always_ff @(posedge clk)begin
    case(addr)
   
 //for K values(called round constant) = first 32 bits of the fractional parts of the cube roots of first 64 prime number(2,3,5....upto 311)//  
          
    7'd0: dataout <= 32'h428af98;
    7'd1: dataout <= 32'h71374491;
    7'd2: dataout <= 32'hb5c0fbcf;
    7'd3: dataout <= 32'he9b5dba5;
    7'd4: dataout <= 32'h3956c25b;
    7'd5: dataout <= 32'h59f111f1;
    7'd6: dataout <= 32'h923f82a4;
    7'd7: dataout <= 32'hab1c5ed5;
    7'd8: dataout <= 32'hd807aa98;
    7'd9: dataout <= 32'h12835b01;
    7'd10: dataout <= 32'h243185be;
    7'd11: dataout <= 32'h550c7dc3;
    7'd12: dataout <= 32'h72be5d74;
    7'd13: dataout <= 32'h80deb1fe;
    7'd14: dataout <= 32'h9bdc06a7;
    7'd15: dataout <= 32'hc19bf174;
    7'd16: dataout <= 32'he49b69c1;
    7'd17: dataout <= 32'hefbe4786;
    7'd18: dataout <= 32'h0fc19dc6;
    7'd19: dataout <= 32'h240ca1cc;
    7'd20: dataout <= 32'h2de92c6f;
    7'd21: dataout <= 32'h4a7484aa;
    7'd22: dataout <= 32'h5cb0a9dc;
    7'd23: dataout <= 32'h76f988da;
    7'd24: dataout <= 32'h983e5152;
    7'd25: dataout <= 32'ha831c66d;
    7'd26: dataout <= 32'hb00327c8;
    7'd27: dataout <= 32'hbf597fc7;
    7'd28: dataout <= 32'hc6e00bf3;
    7'd29: dataout <= 32'hd5a79147;
    7'd30: dataout <= 32'h06ca6351;
    7'd31: dataout <= 32'h14292967;
    7'd32: dataout <= 32'h27b70a85;
    7'd33: dataout <= 32'h2e1b2138;
    7'd34: dataout <= 32'h4d2c6dfc;
    7'd35: dataout <= 32'h53380d13;
    7'd36: dataout <= 32'h650a7354;
    7'd37: dataout <= 32'h766a0abb;
    7'd38: dataout <= 32'h81c2c92c;
    7'd39: dataout <= 32'h92722c85;
    7'd40: dataout <= 32'ha2bfe8a1;
    7'd41: dataout <= 32'ha81a664b;
    7'd42: dataout <= 32'hc24b8b70;
    7'd43: dataout <= 32'hc76c51a3;
    7'd44: dataout <= 32'hd192e819;
    7'd45: dataout <= 32'hd6990624;
    7'd46: dataout <= 32'hf40e3585;
    7'd47: dataout <= 32'h106aa070;
    7'd48: dataout <= 32'h19a4c116;
    7'd49: dataout <= 32'h1e376c08;
    7'd50: dataout <= 32'h2748774c;
    7'd51: dataout <= 32'h34b0bcb5;
    7'd52: dataout <= 32'h391c0cb3;
    7'd53: dataout <= 32'h4ed8aa4a;
    7'd54: dataout <= 32'h5b9cca4f;
    7'd55: dataout <= 32'h682e6ff3;
    7'd56: dataout <= 32'h748f82ee;
    7'd57: dataout <= 32'h78a5636f;
    7'd58: dataout <= 32'h84c87814;
    7'd59: dataout <= 32'h8cc70208;
    7'd60: dataout <= 32'h90befffa;
    7'd61: dataout <= 32'ha4506ceb;
    7'd62: dataout <= 32'hbef9a3f7;
    7'd63: dataout <= 32'hc67178f2;  
   
   ///// for H values(initial values) = first 32 bit of fractional part squareroot of first eight prime no.(2,3,5,7,11,13,17,19)///
   
      7'd64: dataout <= 32'h6a09e667;
      7'd65: dataout <= 32'hbb67ae85;
      7'd66: dataout <= 32'h3c6ef372;
      7'd67: dataout <= 32'ha54ff53a;
      7'd68: dataout <= 32'h510e527f;
      7'd69: dataout <= 32'h9b05688c;
      7'd70: dataout <= 32'h1f83d9ab;
      7'd71: dataout <= 32'h5be0cd19;
      
      default: dataout <= 32'h0;   
   endcase
   end
endmodule

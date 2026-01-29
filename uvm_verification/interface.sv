`timescale 1ns/1ps

interface sha256_if(input logic clk);
    logic [439:0] data_in;
    logic [5:0]   byte_valid;
    logic         data_valid;
    logic         msg_valid;
    logic         rst_n;
    
    logic [255:0] fin_hash;
    logic         hash_done;
    
   clocking cb @(posedge clk);
    default input #1 output #1;
       output msg_valid;
       output byte_valid;
       output data_in;
       output rst_n;
       input hash_done;
       input fin_hash;
   endclocking

    
endinterface

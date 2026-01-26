`include "uvm_macros.svh"
import uvm_pkg::*;

class sha256_seq_item extends uvm_sequence_item;
    rand bit [511:0] block; //messaghe block
    bit [255:0] sha256_expected; //expected output
   
    `uvm_object_utils(sha256_seq_item)
    
    function new(string name = "sha256_seq_item");
        super.new(name);
    endfunction
 endclass
    
    

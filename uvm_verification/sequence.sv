`include "uvm_macros.svh"
import uvm_pkg::*;

class sha256_sequence extends uvm_sequence #(sha256_sequence_item);
    
    `uvm_object_utils(sha256_sequence)
    
    
    function new(string name ="sha256_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        sha256_sequence_item req;
         req = sha256_sequence_item::type_id::create("req");

    repeat(10)begin
        
        
        start_item(req);
       
      if(!req.randomize() with {rst_n == 1;})begin
            `uvm_error("SEQ","Randomization failed")
         end
         
         finish_item(req);
         
      end
   endtask
   
   endclass
  
  class sha256_reset_sequence extends sha256_sequence;
    
    `uvm_object_utils(sha256_reset_sequence)
    
    function new(string name ="sha256_reset_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        sha256_sequence_item req;
        req = sha256_sequence_item::type_id::create("req");
    repeat(1)begin
        
        
        start_item(req);
        
      if(!req.randomize() with {rst_n == 0;})begin
            `uvm_error("SEQ","Randomization failed")
         end
         
         finish_item(req);
         
      end
   endtask
   
   endclass
    
    

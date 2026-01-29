 `include "uvm_macros.svh"
 import uvm_pkg::*;    
  
class sha_sequencer extends uvm_sequencer #(sha256_sequence_item);


     
    `uvm_component_utils(sha256_sequence_item)
    
    function new(string name = "sha256_sequencer",uvm_component parent = null);
        super.new(name,parent);
    endfunction
    
    function build_phase (uvm_phase phase);
    super.build_phase(phase);
    endfunction : build_phase
    
    
    function connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    endfunction : connect_phase
    
    
    task run_phase(uvm_phase phase);
    super.run_phase(phase);
    endtask
    
    endclass

        

`include "uvm_macros.svh"
import uvm_pkg::*;

class sha256_env extends uvm_env;
    sha256_agent agt;
    sha256_scoreboard scb;
    
    `uvm_component_utils(sha256_env)
    
    function new(string name = "sha256_env",uvm_component parent);
            super.new(name,parent);
    endfunction
    
    
    function void build_phase(uvm_phase phase);
            super.build_phase(phase);
       agt = sha256_agent::type_id::create("agt",this);
       scb = sha256_scoreboard::type_id::create("scb",this);
       
      agt.mon.anp.connect(scb.imp);
     endfunction
   endclass
   
       

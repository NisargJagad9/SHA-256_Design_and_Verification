`include "uvm_macros.svh"
 import uvm_pkg::*;

class sha256_test extends uvm_test;
        sha256_env env;
        
        `uvm_component_utils(sha256_test)
        
      function new(string name = "sha256_test",uvm_component parent=null);
        super.new(name,parent);
      endfunction
     
  
      function void build_phase(uvm_phase phase);
        super.build_phase(phase);
       env = sha256_env::type_id::create("env",this);
       endfunction
       
      task run_phase(uvm_phase phase);
        sha256_sequence seq;
        phase.raise_objection(this);
        
        seq = sha256_sequence::type_id::create("seq");
        seq.start(env.agt.seqr);
        
        phase.drop_objection(this);
        endtask
   endclass
        

`include "uvm_macros.svh"
import uvm_pkg::*;

class sha_test extends uvm_test;
`uvm_component_utils(sha_test)

sha256_env env;
sha256_sequence base_seq;
sha256_reset_sequence rst_seq;


  function new(string name="sha_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction:new

 
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = sha256_env::type_id::create("env",this);
  endfunction:build_phase

  task run_phase(uvm_phase phase);
  super.run_phase(phase);
  
  phase.raise_objection(this);
  rst_seq =  sha256_reset_sequence::type_id::create("rst_seq",this);
  rst_seq.start(env.agnt.seqr);
  #10000;
  repeat(10)begin
  base_seq = sha256_sequence::type_id::create("base_seq",this);
  base_seq.start(env.agnt.seqr);
  #20000;
  rst_seq =  sha256_reset_sequence::type_id::create("rst_seq",this);
  rst_seq.start(env.agnt.seqr);
  #10000;
  end
  phase.drop_objection(this);
  
  endtask

  function void end_of_elaboration_phase(uvm_phase phase);
  uvm_top.print_topology();
endfunction


endclass


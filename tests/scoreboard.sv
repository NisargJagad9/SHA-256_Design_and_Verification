`include "uvm_macros.svh"
import uvm_pkg::*;
import sha256_reference_pkg::*;

class sha256_scoreboard extends uvm_component;
    uvm_analysis_imp #(sha256_seq_item,sha256_scoreboard) imp;
    
    `uvm_component_utils(sha256_scoreboard)
    
    function new(string name = "sha256_scoreboard",uvm_component parent=null);
        super.new(name,parent);
        imp = new ("imp",this);
    endfunction
    
  function void write(sha256_seq_item  tr);
        bit[255:0]ref256_expected;
        ref256_expected = sha256_reference(tr.block);
        
        if(ref256_expected ! == tr.expected_expected)
            `uvm_error("sha256_scoreboard",$sformatf("not matched: dut=%h ref=%h",tr.expected_expected,ref256_expected));
         else
            `uvm_info("sha256_scoreboard","Matched",UVM_LOW)
        
  endfunction
endclass

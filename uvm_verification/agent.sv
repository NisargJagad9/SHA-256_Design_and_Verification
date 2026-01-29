`include "uvm_macros.svh"
import uvm_pkg::*;

class sha256_agent extends uvm_agent;
    sha256_driver drv;
    sha256_monitor mon;
    sha_sequencer seqr;
    
    `uvm_component_utils(sha256_agent)
    
    function new(string name = "sha256_agent",uvm_component parent = null);
        super.new(name,parent);
    endfunction

function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqr = sha_sequencer::type_id::create("seqr",this);
    drv = sha256_driver::type_id::create("drv",this);
    mon = sha256_monitor::type_id::create("mon",this);
endfunction

function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
 endfunction
 
endclass

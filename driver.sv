`include "uvm_macros.svh"
import uvm_pkg::*
`include "sha256_seq_item.sv";
`include "hash_core.sv";
`include "sha256_rom.sv";

class sha256_driver extends uvm_driver #(sha256_seq_item);
    virtual hash256 vif;
    
    function new (string name = "sha256_driver",uvm_component parent);
        super.new(name,parent);
    endfunction
    
        task run_phase(uvm_phase phase);
            sha256_seq_item tr;
         forever begin
                seq_item_port.get_next_item(tr);
                
             vif.load_i <= 1'b1;
             @(posedge vif.clk);
             vif.load_i <= 1'b0;  
                
             for ( int i=0;i<64;i++)begin
             
                vif.Kt_i <= K[t];
                
                vif.Wt_i <= schedule_word(tr.block,t);
                @(posedge vif.clk);
              end
              
              seq_item_port.item_done();
             end
         endtask
   endclass
              
              
              
              

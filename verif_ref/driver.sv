`include "uvm_macros.svh"
import uvm_pkg::*;
import sha256_reference_pkg::*;

class sha256_driver extends uvm_driver #(sha256_seq_item);
    virtual hash256 vif;
    
    `uvm_component_utils(sha256_driver)
    
    function new (string name = "sha256_driver",uvm_component parent=null);
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
             
                vif.Kt_i <= K[i];
                
                vif.Wt_i <= schedule_word(tr.block,i);
                @(posedge vif.clk);
              end
              
              seq_item_port.item_done();
             end
         endtask
   endclass
              
              
              
              
              
              
              
              

`include "uvm_macros.svh"
import uvm_pkg::*;

class sha256_driver extends uvm_driver #(sha256_sequence_item);
  virtual sha256_if vif;
  
    `uvm_component_utils(sha256_driver)
    
  function new(string name="sha256_driver", uvm_component parent=null);
    super.new(name, parent);
  endfunction

 
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual sha256_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set for sha256_driver")
  endfunction

function void connect_phase(uvm_phase phase);
super.connect_phase( phase);
endfunction:connect_phase


  task run_phase(uvm_phase phase);
    sha256_sequence_item tr;
    forever begin
      tr = sha256_sequence_item::type_id::create("tr");
      seq_item_port.get_next_item(tr);
      @(posedge vif.clk);
      
      // CORRECTED: Only loop through actual data size, clear rest
      for (int i = 0; i < tr.my_data.size(); i++) begin
          vif.cb.data_in[439 - i*8 -: 8] <= tr.my_data[i];
      end
      
      // Clear remaining bits to avoid 'X' propagation
      for (int i = tr.my_data.size(); i < 55; i++) begin
          vif.cb.data_in[439 - i*8 -: 8] <= 8'h00;
      end
      
      vif.cb.rst_n <= tr.rst_n;
      vif.cb.byte_valid <= tr.my_data.size();
      vif.cb.msg_valid  <= 1;
      @(posedge vif.clk);
      vif.cb.byte_valid <= 0;

      `uvm_info("Driver", $sformatf("rst = %0b, byte_valid  = %0d", tr.rst_n, tr.my_data.size()), UVM_MEDIUM)
      
      
      seq_item_port.item_done();
    end
  endtask
endclass
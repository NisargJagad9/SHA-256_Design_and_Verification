`include "uvm_macros.svh"
import uvm_pkg::*;

// ────────────────────────────────────────────────
// DPI-C import for the SHA-256 hash function
// ────────────────────────────────────────────────
import "DPI-C" function void sha256_hash(
   string         message,     // input message bytes (open array)
  int             msg_len,       // length in bytes
  bit [7:0]       hash[32]       // output: 32-byte digest
);


class sha256_scoreboard extends uvm_scoreboard;

  // ────────────────────────────────────────────────
  // UVM factory registration
  // ────────────────────────────────────────────────
  `uvm_component_utils(sha256_scoreboard)

  // ────────────────────────────────────────────────
  // Analysis port / implementation
  // ────────────────────────────────────────────────
  uvm_analysis_imp #(sha256_sequence_item, sha256_scoreboard) mon_ap;

  // ────────────────────────────────────────────────
  // Statistics & storage
  // ────────────────────────────────────────────────
  int pass   = 0;
  int total  = 0;
  sha256_sequence_item shaitems[$];

  // ────────────────────────────────────────────────
  // Constructor
  // ────────────────────────────────────────────────
  function new(string name = "sha256_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    mon_ap = new("mon_ap", this);
  endfunction

  // ────────────────────────────────────────────────
  // Build phase
  // ────────────────────────────────────────────────
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction : build_phase

  // ────────────────────────────────────────────────
  // Run phase – processes queued transactions
  // ────────────────────────────────────────────────
   task run_phase(uvm_phase phase);
    super.run_phase(phase);
 `uvm_info("SCB", "message", UVM_NONE)
    forever begin
      sha256_sequence_item sha;
      wait(shaitems.size() != 0);
      sha = shaitems.pop_front();
      compare(sha);
    end
  endtask : run_phase

  // ────────────────────────────────────────────────
  // Write implementation (from analysis port)
  // ────────────────────────────────────────────────
   function void write(sha256_sequence_item tr);
    shaitems.push_back(tr);
  endfunction : write

  // ────────────────────────────────────────────────
  // Compare DUT result vs reference model (DPI-C SHA-256)
  // ────────────────────────────────────────────────
   task compare(sha256_sequence_item tr);

    bit [7:0]  ref_hash_bytes[32];           // DPI output format
    bit [255:0] ref_hash_packed;             // for nice printing & comparison


    string msg_str;

    msg_str = string'(tr.my_data);
    // Compute reference hash using DPI-C
    sha256_hash(
      msg_str, 
      tr.my_data.size(), 
      ref_hash_bytes
    );


    `uvm_info("SCOREBOARD", 
        $sformatf("HASH CHECKING  Digest = %h   (len=%0d)", 
                  tr.fin_hash, tr.my_data.size()), 
        UVM_MEDIUM)
    // Pack bytes into 256-bit vector (big-endian byte order)
    ref_hash_packed = {>>{ref_hash_bytes}};

    // Compare
    if (tr.fin_hash !== ref_hash_packed) begin
      `uvm_error("SCOREBOARD", 
        $sformatf("HASH MISMATCH!\n  DUT   = %h\n  REF   = %h\n  DATA LEN = %0d bytes",
                  tr.fin_hash, ref_hash_packed, tr.my_data.size()))
    end 
    else begin
      `uvm_info("SCOREBOARD", 
        $sformatf("HASH MATCHED  Digest = %h   (len=%0d)", 
                  tr.fin_hash, tr.my_data.size()), 
        UVM_MEDIUM)
      pass++;
    end

    total++;
    
    // Optional: report progress every 10 transactions
    if (total % 10 == 0) begin
      `uvm_info("SCOREBOARD", 
        $sformatf("Progress: %0d/%0d passed (%0d%%)", pass, total, (pass*100)/total), 
        UVM_LOW)
    end

  endtask : compare

  // ────────────────────────────────────────────────
  // Optional: report at end of simulation
  // ────────────────────────────────────────────────
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCOREBOARD", 
      $sformatf("FINAL SCORE: %0d / %0d passed  (%0d%%)", 
                pass, total, (total==0 ? 100 : (pass*100)/total)), 
      UVM_LOW)
  endfunction : report_phase

endclass : sha256_scoreboard
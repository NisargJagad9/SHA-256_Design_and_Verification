class sha256_monitor extends uvm_monitor;
  virtual sha256_if vif;
  uvm_analysis_port #(sha256_sequence_item) mon_ap;

  `uvm_component_utils(sha256_monitor)

  function new(string name = "sha256_monitor", uvm_component parent = null);
    super.new(name, parent);
    mon_ap = new("mon_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sha256_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set for sha256_monitor")
  endfunction

  task run_phase(uvm_phase phase);
    sha256_sequence_item tr;
    super.run_phase(phase);

    forever begin
      @(posedge vif.clk);
      // CORRECTED: Uncommented hash_done check
      if (vif.hash_done) begin
        tr = sha256_sequence_item::type_id::create("tr", this);

        tr.fin_hash = vif.fin_hash;

        // CORRECTED: Allocate array before accessing
        tr.my_data = new[55];
        for (int i = 0; i < 55; i++) begin
          tr.my_data[i] = vif.data_in[439 - i*8 -: 8];
          //`uvm_info("MON", $sformatf("my data byte = %0h", tr.my_data[i]), UVM_MEDIUM)
        end

        // CORRECTED: Use correct signal name from interface
        tr.byte_enable = vif.byte_valid;

        `uvm_info("MON", "Hash calculation complete - sending to scoreboard", UVM_MEDIUM)
        mon_ap.write(tr);
      end
    end
  endtask
  
endclass
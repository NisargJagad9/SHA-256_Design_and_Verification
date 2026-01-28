package sha256_reference_pkg;

  import hash_core::*;

  task automatic run_reference(
    input  logic clk,
    input  logic rst_n,
    input  logic [511:0] block,
    output logic [255:0] digest
  );
    // Instantiate hash_core here and drive it with the block
    // Collect digest once done
  endtask

endpackage

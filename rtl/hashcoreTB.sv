`timescale 1ns/1ps

module tb_sha256_core;

    // -----------------------
    // Clock / Reset
    // -----------------------
    logic clk;
    logic rst_n;

    initial clk = 0;
    always #5 clk = ~clk;  // 100 MHz

    // -----------------------
    // DUT Inputs
    // -----------------------
    logic        d_valid;
    logic [31:0] Wt_i;
    logic [31:0] Kt_i;

    // -----------------------
    // DUT Outputs
    // -----------------------
    logic        done;
    logic [255:0] digest_o;

    // -----------------------
    // Instantiate DUT
    // -----------------------
    sha256_core dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .d_valid (d_valid),
        .Wt_i    (Wt_i),
        .Kt_i    (Kt_i),
        .done    (done),
        .digest_o(digest_o)
    );

    // -----------------------
    // SHA-256 Constants K[t]
    // -----------------------
    logic [31:0] K [0:63] = '{
        32'h428a2f98,32'h71374491,32'hb5c0fbcf,32'he9b5dba5,
        32'h3956c25b,32'h59f111f1,32'h923f82a4,32'hab1c5ed5,
        32'hd807aa98,32'h12835b01,32'h243185be,32'h550c7dc3,
        32'h72be5d74,32'h80deb1fe,32'h9bdc06a7,32'hc19bf174,
        32'he49b69c1,32'hefbe4786,32'h0fc19dc6,32'h240ca1cc,
        32'h2de92c6f,32'h4a7484aa,32'h5cb0a9dc,32'h76f988da,
        32'h983e5152,32'ha831c66d,32'hb00327c8,32'hbf597fc7,
        32'hc6e00bf3,32'hd5a79147,32'h06ca6351,32'h14292967,
        32'h27b70a85,32'h2e1b2138,32'h4d2c6dfc,32'h53380d13,
        32'h650a7354,32'h766a0abb,32'h81c2c92e,32'h92722c85,
        32'ha2bfe8a1,32'ha81a664b,32'hc24b8b70,32'hc76c51a3,
        32'hd192e819,32'hd6990624,32'hf40e3585,32'h106aa070,
        32'h19a4c116,32'h1e376c08,32'h2748774c,32'h34b0bcb5,
        32'h391c0cb3,32'h4ed8aa4a,32'h5b9cca4f,32'h682e6ff3,
        32'h748f82ee,32'h78a5636f,32'h84c87814,32'h8cc70208,
        32'h90befffa,32'ha4506ceb,32'hbef9a3f7,32'hc67178f2
    };

    // -----------------------
    // Correct W[t] for "abc"
    // -----------------------
    logic [31:0] W [0:63] = '{
        32'h61626380,32'h00000000,32'h00000000,32'h00000000,
        32'h00000000,32'h00000000,32'h00000000,32'h00000000,
        32'h00000000,32'h00000000,32'h00000000,32'h00000000,
        32'h00000000,32'h00000000,32'h00000000,32'h00000018,
        32'h61626380,32'h000f0000,32'h7da86405,32'h600003c6,
        32'h3e9d7b78,32'h0183fc00,32'h12dcbfdb,32'he2e2c38e,
        32'hc8215c1a,32'hb73679a2,32'hfbecb0f1,32'hae2d0a94,
        32'h1b6f1c9c,32'h3baf7e35,32'h9d6e28f3,32'h2c3b2b6d,
        32'h2fbb2f63,32'h45f8a0a5,32'hc8a06b4d,32'h4a0f44bc,
        32'hc4a1a1aa,32'hf7e97c47,32'h8c4f2b8b,32'h8e3e5e67,
        32'hb8e3c6a6,32'h3f4d3a4a,32'h5a9f83b5,32'h3f4e88b3,
        32'h6d5e8c8b,32'h5c8b6b45,32'h4f2a1a22,32'hbba1b8b6,
        32'h2f2c6e1c,32'h7a7aa6f4,32'hc90f9f1c,32'h4c5f4e31,
        32'h8f6c65a6,32'hc9e9e4c4,32'h3a8b7c72,32'h2f06d4aa,
        32'hd6a3a38a,32'h4b66e2f3,32'hd7a7b8f6,32'h5b8310d1
    };

    // -----------------------
    // Test Sequence
    // -----------------------
    initial begin
        rst_n   = 0;
        d_valid = 0;
        Wt_i    = 0;
        Kt_i    = 0;

        // Reset
        repeat (3) @(posedge clk);
        rst_n = 1;

        // Load initial hash values
        @(posedge clk);
        d_valid = 1;
        @(posedge clk);
        d_valid = 0;

        // Apply 64 rounds
        for (int t = 0; t < 64; t++) begin
            @(posedge clk);
            Wt_i = W[t];
            Kt_i = K[t];
        end

        // Wait for completion
        wait (done);

        $display("Digest = %h", digest_o);

        if (digest_o ==
            256'hBA7816BF8F01CFEA414140DE5DAE2223
                 B00361A396177A9CB410FF61F20015AD)
            $display("✅ SHA-256 CORE PASSED");
        else
            $display("❌ SHA-256 CORE FAILED");

        $finish;
    end

endmodule

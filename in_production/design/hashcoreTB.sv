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
        W[ 0] = 32'h61626380;
    W[ 1] = 32'h00000000;
    W[ 2] = 32'h00000000;
    W[ 3] = 32'h00000000;
    W[ 4] = 32'h00000000;
    W[ 5] = 32'h00000000;
    W[ 6] = 32'h00000000;
    W[ 7] = 32'h00000000;
    W[ 8] = 32'h00000000;
    W[ 9] = 32'h00000000;
    W[10] = 32'h00000000;
    W[11] = 32'h00000000;
    W[12] = 32'h00000000;
    W[13] = 32'h00000000;
    W[14] = 32'h00000000;
    W[15] = 32'h00000018;

    W[16] = 32'h61626380;
    W[17] = 32'h000F0000;
    W[18] = 32'h7DA86405;
    W[19] = 32'h600003C6;
    W[20] = 32'h3E9D7B78;
    W[21] = 32'h0183FC00;
    W[22] = 32'h12DCA805;
    W[23] = 32'hC19BF174;
    W[24] = 32'h6C9F0D6F;
    W[25] = 32'h8F2E2E60;
    W[26] = 32'h5A7A5C15;
    W[27] = 32'h9F1B2B9E;
    W[28] = 32'hD807AA98;
    W[29] = 32'h12835B01;
    W[30] = 32'h243185BE;
    W[31] = 32'h550C7DC3;

    W[32] = 32'h72BE5D74;
    W[33] = 32'h80DEB1FE;
    W[34] = 32'h9BDC06A7;
    W[35] = 32'hC19BF3F4;
    W[36] = 32'hE49B69C1;
    W[37] = 32'hEFBE4786;
    W[38] = 32'h0FC19DC6;
    W[39] = 32'h240CA1CC;
    W[40] = 32'h2DE92C6F;
    W[41] = 32'h4A7484AA;
    W[42] = 32'h5CB0A9DC;
    W[43] = 32'h76F988DA;
    W[44] = 32'h983E5152;
    W[45] = 32'hA831C66D;
    W[46] = 32'hB00327C8;
    W[47] = 32'hBF597FC7;

    W[48] = 32'hC6E00BF3;
    W[49] = 32'hD5A79147;
    W[50] = 32'h06CA6351;
    W[51] = 32'h14292967;
    W[52] = 32'h27B70A85;
    W[53] = 32'h2E1B2138;
    W[54] = 32'h4D2C6DFC;
    W[55] = 32'h53380D13;
    W[56] = 32'h650A7354;
    W[57] = 32'h766A0ABB;
    W[58] = 32'h81C2C92E;
    W[59] = 32'h92722C85;
    W[60] = 32'hA2BFE8A1;
    W[61] = 32'hA81A664B;
    W[62] = 32'hC24B8B70;
    W[63] = 32'hC76C51A3;
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

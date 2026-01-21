// ============================================================================
// SHA-256 Hash Core Logic
//  - Single-cycle combinational round
//  - Registers a..h
//  - Implements Σ0, Σ1, Maj, Ch
//  - Optimized for minimal registers (ASIC style)
// ============================================================================

module sha256_hash_core (
    input  logic         clk,
    input  logic         rst_n,

    // Control
    input  logic         ld_i,     // Load initial hash values
    input  logic         en_i,     // Enable round

    // Inputs
    input  logic [31:0]  Wt_i,
    input  logic [31:0]  Kt_i,

    // Hash outputs (final values read externally)
    output logic [31:0]  A_o,
    output logic [31:0]  B_o,
    output logic [31:0]  C_o,
    output logic [31:0]  D_o,
    output logic [31:0]  E_o,
    output logic [31:0]  F_o,
    output logic [31:0]  G_o,
    output logic [31:0]  H_o
);

    // ------------------------------------------------------------------------
    // Hash state registers
    // ------------------------------------------------------------------------
    logic [31:0] a, b, c, d, e, f, g, h;

    // ------------------------------------------------------------------------
    // Rotate right
    // ------------------------------------------------------------------------
    function automatic logic [31:0] rotr (
        input logic [31:0] x,
        input int unsigned n
    );
        rotr = (x >> n) | (x << (32 - n));
    endfunction

    // ------------------------------------------------------------------------
    // SHA-256 functions
    // ------------------------------------------------------------------------
    logic [31:0] Sigma0, Sigma1;
    logic [31:0] Maj, Ch;

    assign Sigma0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
    assign Sigma1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);

    assign Maj = (a & b) ^ (a & c) ^ (b & c);
    assign Ch  = (e & f) ^ (~e & g);

    // ------------------------------------------------------------------------
    // Round computation
    // ------------------------------------------------------------------------
    logic [31:0] T1, T2;

    assign T1 = h + Sigma1 + Ch + Kt_i + Wt_i;
    assign T2 = Sigma0 + Maj;

    // ------------------------------------------------------------------------
    // State update
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a <= 32'd0; b <= 32'd0; c <= 32'd0; d <= 32'd0;
            e <= 32'd0; f <= 32'd0; g <= 32'd0; h <= 32'd0;
        end
        else if (ld_i) begin
            // Initial SHA-256 IV values (FIPS-180-4)
            a <= 32'h6a09e667;
            b <= 32'hbb67ae85;
            c <= 32'h3c6ef372;
            d <= 32'ha54ff53a;
            e <= 32'h510e527f;
            f <= 32'h9b05688c;
            g <= 32'h1f83d9ab;
            h <= 32'h5be0cd19;
        end
        else if (en_i) begin
            h <= g;
            g <= f;
            f <= e;
            e <= d + T1;
            d <= c;
            c <= b;
            b <= a;
            a <= T1 + T2;
        end
    end

    // ------------------------------------------------------------------------
    // Outputs
    // ------------------------------------------------------------------------
    assign A_o = a;
    assign B_o = b;
    assign C_o = c;
    assign D_o = d;
    assign E_o = e;
    assign F_o = f;
    assign G_o = g;
    assign H_o = h;

endmodule




module rotr(
        input x, n, w,
        output rotrght
        );

assign rotrght = (x >> n) | (x << (w-n));

endmodule


module choose( 
        input x,y,z,
        output ch
        );

assign kk = (x & y) ^ ((~x) & z);

endmodule 

module majority(
            input x, y, z,
            output maj
            );
          
assign maj = (x & y) ^ (x & z) ^ (y & z);

endmodule

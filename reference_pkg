package sha256_reference_pkg;

    const logic [31:0] K [0:63] = '{
        32'h428a2f98,32'h71374491,32'hb5c0fbcf,32'he9b5dba5,
        32'h3956c25b,32'h59f111f1,32'h923f82a4,32'hab1c5ed5,
        32'hd807aa98,32'h12835b01,32'h243185be,32'h550c7dc3,
        32'h72be5d74,32'h80deb1fe,32'h9bdc06a7,32'hc19bf174,
        32'he49b69c1,32'hefbe4786,32'h0fc19dc6,32'h240ca1cc,
        32'h2de92c6f,32'h4a7484aa,32'h5cb0a9dc,32'h76f988da,
        32'h983e5152,32'ha831c66d,32'hb00327c8,32'hbf597fc7,
        32'hc6e00bf3,32'hd5a79147,32'h06ca6351,32'h14292967,
        32'h27b70a85,32'h2e1b2138,32'h4d2c6dfc,32'h53380d13,
        32'h650a7354,32'h766a0abb,32'h81c2c92c,32'h92722c85,
        32'ha2bfe8a1,32'ha81a664b,32'hc24b8b70,32'hc76c51a3,
        32'hd192e819,32'hd6990624,32'hf40e3585,32'h106aa070,
        32'h19a4c116,32'h1e376c08,32'h2748774c,32'h34b0bcb5,
        32'h391c0cb3,32'h4ed8aa4a,32'h5b9cca4f,32'h682e6ff3,
        32'h748f82ee,32'h78a5636f,32'h84c87814,32'h8cc70208,
        32'h90befffa,32'ha4506ceb,32'hbef9a3f7,32'hc67178f2
    };

    const logic [31:0] H_init [0:7] = '{
        32'h6a09e667,32'hbb67ae85,32'h3c6ef372,32'ha54ff53a,
        32'h510e527f,32'h9b05688c,32'h1f83d9ab,32'h5be0cd19
    };

    function automatic logic [31:0] rotr(input logic [31:0] x, input int n);
        return {x>>n |  x<<(32-n)};
    endfunction

    function automatic logic [31:0] Sigma0(input logic [31:0] x);
        return rotr(x,2) ^ rotr(x,13) ^ rotr(x,22);
    endfunction

    function automatic logic [31:0] Sigma1(input logic [31:0] x);
        return rotr(x,6) ^ rotr(x,11) ^ rotr(x,25);
    endfunction

    function automatic logic [31:0] sigma0(input logic [31:0] x);
        return rotr(x,7) ^ rotr(x,18) ^ (x >> 3);
    endfunction

    function automatic logic [31:0] sigma1(input logic [31:0] x);
        return rotr(x,17) ^ rotr(x,19) ^ (x >> 10);
    endfunction

    function automatic logic [31:0] schedule_word(input logic [511:0] block, input int t);
        logic [31:0] W [0:63];
        int i;
        for (i=0; i<16; i++) W[i] = block[511-(32*i) -: 32];
        for (i=16; i<=t; i++) W[i] = sigma1(W[i-2]) + W[i-7] + sigma0(W[i-15]) + W[i-16];
        return W[t];
    endfunction

    function automatic logic [255:0] sha256_reference(input logic [511:0] block);
        logic [31:0] W [0:63];
        logic [31:0] a,b,c,d,e,f,g,h,T1,T2;
        logic [31:0] H [0:7];
        int t;

        for (t=0; t<16; t++) W[t] = block[511-(32*t) -: 32];
        for (t=16; t<64; t++) W[t] = sigma1(W[t-2]) + W[t-7] + sigma0(W[t-15]) + W[t-16];

        for (t=0; t<8; t++) H[t] = H_init[t];
        a=H[0]; b=H[1]; c=H[2]; d=H[3];
        e=H[4]; f=H[5]; g=H[6]; h=H[7];

        for (t=0; t<64; t++) begin
            T1 = h + Sigma1(e) + ((e & f) ^ (~e & g)) + K[t] + W[t];
            T2 = Sigma0(a) + ((a & b) ^ (a & c) ^ (b & c));
            h=g; g=f; f=e; e=d+T1;
            d=c; c=b; b=a; a=T1+T2;
        end

        H[0] = H[0]+a; H[1]= H[1]+b; 
        H[2]= H[2]+c; H[3]= H[3]+d;
        H[4]= H[4]+e; H[5]= H[5]+f;
        H[6]= H[6]+g; H[7]= H[7]+h;

        return {H[0],H[1],H[2],H[3],H[4],H[5],H[6],H[7]};
    endfunction
endpackage

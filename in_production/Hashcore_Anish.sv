module hashcore(
    input logic clk,
    input logic rst_n,
    input bit load,
    
    // Inputs for this round
    input  logic [31:0] Kt_i,  // round constant
    input  logic [31:0] Wt_i,  // message schedule word

    //initial hash value
    input  logic [31:0] A_i, B_i, C_i, D_i, E_i, F_i, G_i, H_i,

    // Outputs
    output logic [31:0] A_o, B_o, C_o, D_o, E_o, F_o, G_o, H_o,
    output logic [255:0] finall,
    output logic done          // flag when all 64 rounds complete
);

// registers

logic [31:0] a, b, c, d, e, f, g, h;
logic [5:0]  round_cnt;  // counts 0..63

//SHA uses different nonlinear functions in different paths so that the state evolution is not biased toward a single type of logic behavior.
//Ch introduces selector-style dependency, while Maj introduces consensus-style dependency.
//Together, they prevent structural patterns and improve diffusion across rounds.

//CHOICE FUNCTION          ch(x,y,z) → nonlinear selector
//If x=1, we get y.
//If x=0, we get z.

function automatic logic [31:0] Ch(
        input logic [31:0] x,
        input logic [31:0] y,
        input logic [31:0] z
        );
    
    Ch = (x & y) ^ (~x & z);

endfunction
    
//MAJORITY FUNCTION            maj(x,y,z) → nonlinear voting
function automatic logic [31:0] Maj(
        input logic [31:0] x,
        input logic [31:0] y,
        input logic [31:0] z
);

    Maj = (x & y)^(x & z)^(y & z);

endfunction

//Rotate is just wiring, no logic cost.
//rotr(x,n) → bit diffusion primitive
function automatic logic [31:0] rotr(
        input logic [31:0] x,
        input int unsigned n

);

    rotr = (x >> n )| (x << (32-n));

endfunction

//This is a diffusion function.
//big_sigma_0(x) → state diffusion
//big_sigma_1(x) → state diffusion
function automatic logic [31:0] big_sigma_0(
        input logic [31:0] x
);

    big_sigma_0 = rotr(x,2) ^ rotr(x,13) ^ rotr(x,22);

endfunction

function automatic logic [31:0] big_sigma_1(
        input logic [31:0] x
);

    big_sigma_1 = rotr(x,6) ^ rotr(x,11) ^ rotr(x,25);

endfunction


logic [31:0] T1, T2;

//One path that pulls in the message
//message + constant + some internal bits
assign T1 = h + big_sigma_1(e) + Ch(e,f,g) + Kt_i + Wt_i;

//One path that scrambles existing state
//scrambles internal state
assign T2 = big_sigma_0(a) + Maj(a,b,c);


//Every cycle, deeply change a and e, shift the rest.
//Only a and e directly absorb new computed complexity each round.
//The rest still get affected indirectly because they receive previous values of a and e over subsequent rounds.

always_ff @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            a <= 32'd0;
            b <= 32'd0;
            c <= 32'd0;
            d <= 32'd0;
            e <= 32'd0;
            f <= 32'd0;
            g <= 32'd0;
            h <= 32'd0;
            done <= 1'b0;
            round_cnt <= 6'd0;
        end
    else if(load)
        begin
            a <= A_i;
            b <= B_i;
            c <= C_i;
            d <= D_i;
            e <= E_i;
            f <= F_i;
            g <= G_i;
            h <= H_i;
            round_cnt <= 6'd0;
            done <= 1'b0;
        end
    else if(!done)
        begin
            h <= g ;
            g <= f ;
            f <= e ; 
            d <= c ;
            c <= b ;
            b <= a ;
            e <= d + T1 ;
            a <= T1 + T2 ;
            round_cnt <= round_cnt +1 ;
            
            if(round_cnt == 63)
                done <= 1'b1;
        end

end

assign A_o = a + A_i;
assign B_o = b + B_i;
assign C_o = c + C_i;
assign D_o = d + D_i;
assign E_o = e + E_i;
assign F_o = f + F_i;
assign G_o = g + G_i;
assign H_o = h + H_i;

assign finall = {A_o, B_o, C_o, D_o, E_o, F_o, G_o, H_o};

endmodule

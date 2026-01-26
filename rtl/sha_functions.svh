//This file contains all the functions used in message scheduling


function automatic [31:0] ROTR;
    input [31:0] x;
    input [4:0]  n;

    begin
            ROTR = (x >> n) | (x << (32-n));
    end
endfunction

function automatic [31:0] SHR;
    input [31:0] x;
    input [4:0]  n;

    begin
            SHR = x >> n;
    end
endfunction

function automatic [31:0] sigma0;
    input [31:0] x;

    begin
        sigma0 = ROTR(x,7) ^ ROTR(x,18) ^ SHR(x,3);
    end
endfunction


function automatic [31:0] sigma1;
    input [31:0] x;

    begin
        sigma1 = ROTR(x,17) ^ ROTR(x,19) ^ SHR(x,10);
    end
endfunction

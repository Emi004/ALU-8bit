`include "bitadder8.v"
`include "bitmultiplier.v"
`include "bitdivision.v"
`include "mux4.v"

module alu (
);
    wire[8:0]a,b;    

    bitadder8 BITADDER8();
    bitadder8 BITSUBTRACTOR8();
    bitmultiplier BITMULTIPLIER();
    bitdivision BITDIVISION();
    mux4 MUX4();

endmodule
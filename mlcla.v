module AC(
	input xi, yi, ci,
	output zi, gi, pi
);


assign    gi = xi & yi;
assign    pi = xi | yi;
assign    zi = xi ^ yi ^ ci;


endmodule

module BplusC(
    input gjk, pjk, gij, pij, ci,
    output reg gik, pik, co
);

always @(*) begin
    gik = gjk | (gij & pjk);
    pik = pjk & pij;
    co = (ci & pij) | gij;
end

endmodule

module mlcla(
    input [7:0] x, y, input select,start,
    output c8, output [7:0]z, output overflow, negative, zero
);

wire [14:0] g,p;
wire [6:0] c;


AC bit0(.xi(x[0]), .yi(y[0] ^ select), .ci(select), .zi(z[0]), .gi(g[0]), .pi(p[0])); 
AC bit1(.xi(x[1]), .yi(y[1] ^ select), .ci(c[0]), .zi(z[1]), .gi(g[1]), .pi(p[1]));
AC bit2(.xi(x[2]), .yi(y[2] ^ select), .ci(c[1]), .zi(z[2]), .gi(g[2]), .pi(p[2]));
AC bit3(.xi(x[3]), .yi(y[3] ^ select), .ci(c[2]), .zi(z[3]), .gi(g[3]), .pi(p[3]));

AC bit4(.xi(x[4]), .yi(y[4] ^ select), .ci(c[3]), .zi(z[4]), .gi(g[7]), .pi(p[7])); 
AC bit5(.xi(x[5]), .yi(y[5] ^ select), .ci(c[4]), .zi(z[5]), .gi(g[8]), .pi(p[8]));
AC bit6(.xi(x[6]), .yi(y[6] ^ select), .ci(c[5]), .zi(z[6]), .gi(g[9]), .pi(p[9]));
AC bit7(.xi(x[7]), .yi(y[7] ^ select), .ci(c[6]), .zi(z[7]), .gi(g[10]), .pi(p[10]));

BplusC unu(.gjk(g[1]), .pjk(p[1]), .gij(g[0]), .pij(p[0]), .ci(select), .gik(g[4]), .pik(p[4]), .co(c[0]));

BplusC doi(.gjk(g[3]), .pjk(p[3]), .gij(g[2]), .pij(p[2]), .ci(c[1]), .gik(g[5]), .pik(p[5]), .co(c[2]));

BplusC trei(.gjk(g[5]), .pjk(p[5]), .gij(g[4]), .pij(p[4]), .ci(select), .gik(g[6]), .pik(p[6]), .co(c[1]));
// 
BplusC patru(.gjk(g[8]), .pjk(p[8]), .gij(g[7]), .pij(p[7]), .ci(c[3]), .gik(g[11]), .pik(p[11]), .co(c[4]));

BplusC cinci(.gjk(g[10]), .pjk(p[10]), .gij(g[9]), .pij(p[9]), .ci(c[5]), .gik(g[12]), .pik(p[12]), .co(c[6]));

BplusC sase(.gjk(g[12]), .pjk(p[12]), .gij(g[11]), .pij(p[11]), .ci(c[3]), .gik(g[13]), .pik(p[13]), .co(c[5]));

BplusC sapte(.gjk(g[13]), .pjk(p[13]), .gij(g[6]), .pij(p[6]), .ci(select), .gik(g[14]), .pik(p[14]), .co(c[3]));

assign c8 = (select & p[14]) | g[14];
assign overflow = start ? ((x[7] & y[7] & ~z[7]) | (~x[7] & ~y[7] & z[7])) : 1'b0;
assign negative = start ? z[7] : 1'b0;
assign zero = start ? ~(z[7] | z[6] | z[5] | z[4] | z[3] | z[2] | z[1] | z[0]) : 1'b0;


endmodule

`timescale 1ns/1ps

module mlcla8bit_tb();

// Inputs
reg [7:0] a;
reg [7:0] b;
reg select;
reg start;

// Outputs
wire [7:0] sum;
wire carry_out;
wire overflow;
wire negative;
wire zero;

// Instantiate DUT
mlcla dut (
    .x(a),
    .y(b),
    .select(select),
    .start(start),
    .z(sum),
    .c8(carry_out),
    .overflow(overflow),
    .zero(zero),
    .negative(negative)
);

initial begin
    // Create waveform dump file
    $dumpfile("mlcla_wave.vcd");
    $dumpvars(0, mlcla8bit_tb);
    
    // Initialize inputs
    a = 0;
    b = 0;
    select = 0;
    start = 1;  // Enable the adder
    
    // Wait a little then run test cases
    #10;
    
    // Test case 1: Simple addition (no overflow)
    a = 8'd50;    // 50
    b = 8'd30;    // 30
    select = 0;   // Addition
    #20;
    $display("Test 1: %d + %d = %d (Sum=%h, Carry=%b, OF=%b, Neg=%b, Zero=%b)",
             a, b, sum, sum, carry_out, overflow, negative, zero);
    
    // Test case 2: Addition with overflow
    a = 8'd127;   // 127 (max positive)
    b = 8'd1;     // 1
    select = 0;   // Addition
    #20;
    $display("Test 2: %d + %d = %d (Sum=%h, Carry=%b, OF=%b, Neg=%b, Zero=%b)",
             a, b, sum, sum, carry_out, overflow, negative, zero);
    
    // Test case 3: Simple subtraction
    a = 8'd80;    // 80
    b = 8'd48;    // 48
    select = 1;   // Subtraction
    #20;
    $display("Test 3: %d - %d = %d (Sum=%h, Carry=%b, OF=%b, Neg=%b, Zero=%b)",
             a, b, sum, sum, carry_out, overflow, negative, zero);
    
    // Test case 4: Subtraction with negative result
    a = 8'd30;    // 30
    b = 8'd50;    // 50
    select = 1;   // Subtraction
    #20;
    $display("Test 4: %d - %d = %d (Sum=%h, Carry=%b, OF=%b, Neg=%b, Zero=%b)",
             a, b, $signed(sum), sum, carry_out, overflow, negative, zero);
    
    // Test case 5: Subtraction with zero result
    a = 8'd100;   // 100
    b = 8'd100;   // 100
    select = 1;   // Subtraction
    #20;
    $display("Test 5: %d - %d = %d (Sum=%h, Carry=%b, OF=%b, Neg=%b, Zero=%b)",
             a, b, sum, sum, carry_out, overflow, negative, zero);
    
    $display("\nTesting complete");
    $finish;
end

endmodule
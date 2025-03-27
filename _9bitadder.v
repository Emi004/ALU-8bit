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

module _9bitadder(
    input [8:0] x, y, input select,
    output c9, output [8:0]z, output overflow, negative, zero
);

wire [16:0] g,p;
wire [7:0] c;

AC bit0(.xi(x[0]), .yi(y[0] ^ select), .ci(select), .zi(z[0]), .gi(g[0]), .pi(p[0])); 
AC bit1(.xi(x[1]), .yi(y[1] ^ select), .ci(c[0]), .zi(z[1]), .gi(g[1]), .pi(p[1]));
AC bit2(.xi(x[2]), .yi(y[2] ^ select), .ci(c[1]), .zi(z[2]), .gi(g[2]), .pi(p[2]));
AC bit3(.xi(x[3]), .yi(y[3] ^ select), .ci(c[2]), .zi(z[3]), .gi(g[3]), .pi(p[3]));

AC bit4(.xi(x[4]), .yi(y[4] ^ select), .ci(c[3]), .zi(z[4]), .gi(g[7]), .pi(p[7])); 
AC bit5(.xi(x[5]), .yi(y[5] ^ select), .ci(c[4]), .zi(z[5]), .gi(g[8]), .pi(p[8]));
AC bit6(.xi(x[6]), .yi(y[6] ^ select), .ci(c[5]), .zi(z[6]), .gi(g[9]), .pi(p[9]));
AC bit7(.xi(x[7]), .yi(y[7] ^ select), .ci(c[6]), .zi(z[7]), .gi(g[10]), .pi(p[10]));

AC bit8(.xi(x[8]), .yi(y[8] ^ select), .ci(c[7]), .zi(z[8]), .gi(g[15]), .pi(p[15]));

BplusC unu(.gjk(g[1]), .pjk(p[1]), .gij(g[0]), .pij(p[0]), .ci(select), .gik(g[4]), .pik(p[4]), .co(c[0]));

BplusC doi(.gjk(g[3]), .pjk(p[3]), .gij(g[2]), .pij(p[2]), .ci(c[1]), .gik(g[5]), .pik(p[5]), .co(c[2]));

BplusC trei(.gjk(g[5]), .pjk(p[5]), .gij(g[4]), .pij(p[4]), .ci(select), .gik(g[6]), .pik(p[6]), .co(c[1]));
// 
BplusC patru(.gjk(g[8]), .pjk(p[8]), .gij(g[7]), .pij(p[7]), .ci(c[3]), .gik(g[11]), .pik(p[11]), .co(c[4]));

BplusC cinci(.gjk(g[10]), .pjk(p[10]), .gij(g[9]), .pij(p[9]), .ci(c[5]), .gik(g[12]), .pik(p[12]), .co(c[6]));

BplusC sase(.gjk(g[12]), .pjk(p[12]), .gij(g[11]), .pij(p[11]), .ci(c[3]), .gik(g[13]), .pik(p[13]), .co(c[5]));

BplusC sapte(.gjk(g[13]), .pjk(p[13]), .gij(g[6]), .pij(p[6]), .ci(select), .gik(g[14]), .pik(p[14]), .co(c[3]));

BplusC opt(.gjk(g[15]), .pjk(p[15]), .gij(g[14]), .pij(p[14]), .ci(select), .gik(g[16]), .pik(p[16]), .co(c[7]));

assign c9 = (select & p[16]) | g[16];
assign overflow = (x[7] & y[7] & ~z[7]) | (~x[7] & ~y[7] & z[7]);
assign negative = z[7];
assign zero = ~( z[7] | z[6] | z[5] | z[4] | z[3] | z[2] | z[1] | z[0] );

endmodule

`timescale 1ns/1ps

module mlcla9bit_tb();

// Inputs
reg [8:0] a;
reg [8:0] b;
reg select;

// Outputs
wire [8:0] sum;
wire carry_out;
wire overflow;
wire negative;
wire zero;

// Instantiate DUT
_9bitadder dut (
    .x(a),
    .y(b),
    .select(select),
    .z(sum),
    .c9(carry_out),
    .overflow(overflow),
    .negative(negative),
    .zero(zero)
);

// Helper function to display signed values
function signed [31:0] display_signed;
    input [8:0] value;
    begin
        if (value[8]) begin
            display_signed = -(256 - value);
        end else begin
            display_signed = value;
        end
    end
endfunction

initial begin
    // Initialize inputs
    a = 0;
    b = 0;
    select = 0;
    
    // Wait a little then run test cases
    #10;
    
    $display("Testing 9-bit Adder/Subtractor");
    $display("=====================================");
    
    // Test case 1: Simple addition (no overflow)
    a = 9'b001001111;     // 79
    b = 9'b000110000;     // 48
    select = 0;           // Add operation
    #10;
    $display("Test 1: %0d + %0d = %0d (Expected: %0d)", 
             display_signed(a), display_signed(b), display_signed(sum), 
             display_signed(a) + display_signed(b));
    $display("Carry: %b, Overflow: %b, Negative: %b, Zero: %b", 
             carry_out, overflow, negative, zero);
    $display("=====================================");
    
    // Test case 2: Addition with overflow
    a = 9'b010000000;     // 128
    b = 9'b010000000;     // 128
    select = 0;           // Add operation
    #10;
    $display("Test 2: %0d + %0d = %0d (Expected overflow)", 
             display_signed(a), display_signed(b), display_signed(sum));
    $display("Carry: %b, Overflow: %b (Expected: 1), Negative: %b, Zero: %b", 
             carry_out, overflow, negative, zero);
    $display("=====================================");
    
    // Test case 3: Subtraction (select = 1)
    a = 9'b000111101;     // 61
    b = 9'b000011001;     // 25
    select = 1;           // Subtract operation
    #10;
    $display("Test 3: %0d - %0d = %0d (Expected: %0d)", 
             display_signed(a), display_signed(b), display_signed(sum), 
             display_signed(a) - display_signed(b));
    $display("Carry: %b, Overflow: %b, Negative: %b, Zero: %b", 
             carry_out, overflow, negative, zero);
    $display("=====================================");
    
    // Test case 4: Negative result
    a = 9'b000001000;     // 8
    b = 9'b000010000;     // 16
    select = 1;           // Subtract operation
    #10;
    $display("Test 4: %0d - %0d = %0d (Expected: %0d)", 
             display_signed(a), display_signed(b), display_signed(sum), 
             display_signed(a) - display_signed(b));
    $display("Carry: %b, Overflow: %b, Negative: %b (Expected: 1), Zero: %b", 
             carry_out, overflow, negative, zero);
    $display("=====================================");
    
    // Test case 5: Zero result
    a = 9'b000100000;     // 32
    b = 9'b000100000;     // 32
    select = 1;           // Subtract operation
    #10;
    $display("Test 5: %0d - %0d = %0d (Expected: 0)", 
             display_signed(a), display_signed(b), display_signed(sum));
    $display("Carry: %b, Overflow: %b, Negative: %b, Zero: %b (Expected: 1)", 
             carry_out, overflow, negative, zero);
    $display("=====================================");
    
    // Test case 6: Large numbers
    a = 9'b111111111;     // -1
    b = 9'b111111111;     // -1
    select = 0;           // Add operation
    #10;
    $display("Test 6: %0d + %0d = %0d (Expected: %0d)", 
             display_signed(a), display_signed(b), display_signed(sum), 
             display_signed(a) + display_signed(b));
    $display("Carry: %b, Overflow: %b, Negative: %b, Zero: %b", 
             carry_out, overflow, negative, zero);
    $display("=====================================");
    
    // Test case 7: Carry out
    a = 9'b111111111;     // -1
    b = 9'b000000001;     // 1
    select = 0;           // Add operation
    #10;
    $display("Test 7: %0d + %0d = %0d (Expected: 0)", 
             display_signed(a), display_signed(b), display_signed(sum));
    $display("Carry: %b (Expected: 1), Overflow: %b, Negative: %b, Zero: %b (Expected: 1)", 
             carry_out, overflow, negative, zero);
    $display("=====================================");
    
    $display("\n9-bit adder testing complete");
    $finish;
end

endmodule
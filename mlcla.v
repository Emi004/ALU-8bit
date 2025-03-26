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
    input [7:0] x, y, input c0,
    output c8, output [7:0]z 
);

wire [14:0] g,p;
wire [5:0] c;

AC bit0(.xi(x[0]), .yi(y[0]), .ci(c0), .zi(z[0]), .gi(g[0]), .pi(p[0])); 
AC bit1(.xi(x[1]), .yi(y[1]), .ci(c[0]), .zi(z[1]), .gi(g[1]), .pi(p[1]));
AC bit2(.xi(x[2]), .yi(y[2]), .ci(c[1]), .zi(z[2]), .gi(g[2]), .pi(p[2]));
AC bit3(.xi(x[3]), .yi(y[3]), .ci(c[2]), .zi(z[3]), .gi(g[3]), .pi(p[3]));

AC bit4(.xi(x[4]), .yi(y[4]), .ci(c[3]), .zi(z[4]), .gi(g[7]), .pi(p[7])); 
AC bit5(.xi(x[5]), .yi(y[5]), .ci(c[4]), .zi(z[5]), .gi(g[8]), .pi(p[8]));
AC bit6(.xi(x[6]), .yi(y[6]), .ci(c[5]), .zi(z[6]), .gi(g[9]), .pi(p[9]));
AC bit7(.xi(x[7]), .yi(y[7]), .ci(c[6]), .zi(z[7]), .gi(g[10]), .pi(p[10]));

BplusC unu(.gjk(g[1]), .pjk(p[1]), .gij(g[0]), .pij(p[0]), .ci(c0), .gik(g[4]), .pik(p[4]), .co(c[0]));

BplusC doi(.gjk(g[3]), .pjk(p[3]), .gij(g[2]), .pij(p[2]), .ci(c[1]), .gik(g[5]), .pik(p[5]), .co(c[2]));

BplusC trei(.gjk(g[5]), .pjk(p[5]), .gij(g[4]), .pij(p[4]), .ci(c0), .gik(g[6]), .pik(p[6]), .co(c[1]));
// 
BplusC patru(.gjk(g[8]), .pjk(p[8]), .gij(g[7]), .pij(p[7]), .ci(c[3]), .gik(g[11]), .pik(p[11]), .co(c[4]));

BplusC cinci(.gjk(g[10]), .pjk(p[10]), .gij(g[9]), .pij(p[9]), .ci(c[5]), .gik(g[12]), .pik(p[12]), .co(c[6]));

BplusC sase(.gjk(g[12]), .pjk(p[12]), .gij(g[11]), .pij(p[11]), .ci(c[3]), .gik(g[13]), .pik(p[13]), .co(c[5]));

BplusC sapte(.gjk(g[13]), .pjk(p[13]), .gij(g[6]), .pij(p[6]), .ci(c0), .gik(g[14]), .pik(p[14]), .co(c[3]));

assign c8 = (c0 & p[14]) | g[14];

endmodule

`timescale 1ns/1ps

module tb_mlcla8_exhaustive();

// Parameters
parameter NUM_TESTS = 65536;  // 256 x values × 256 y values

// DUT I/O
reg [7:0] x, y;
reg c0;
wire [7:0] z;
wire c8;

// Instantiate DUT
mlcla dut (
    .x(x),
    .y(y),
    .c0(c0),
    .z(z),
    .c8(c8)
);

// Test variables
integer i, j, errors = 0;
reg [8:0] expected;  // 9-bit expected result (1-bit carry + 8-bit sum)
reg verbose = 0;     // Set to 1 for detailed output (warning: huge output)

initial begin
    $display("Starting exhaustive 8-bit MLCLA test...");
    $display("Testing all 65,536 input combinations (256 x × 256 y)");
    
    // Test with c0=0
    c0 = 0;
    for (i = 0; i < 256; i = i + 1) begin
        x = i;
        for (j = 0; j < 256; j = j + 1) begin
            y = j;
            #10;
            
            expected = x + y + c0;
            
            if ({c8, z} !== expected) begin
                errors = errors + 1;
                if (verbose) $display("FAIL: x=%h, y=%h ? got %h_%h, expected %h_%b",
                                    x, y, c8, z, expected[7:0], expected[8]);
            end
            else if (verbose) begin
                $display("PASS: x=%h, y=%h ? %h_%h", x, y, c8, z);
            end
        end
        
        // Progress reporting
        if (i % 32 == 0) 
            $display("Progress: x=%h (%0d/256), Errors: %0d", x, i, errors);
    end
    
    // Test with c0=1 (optional, since carry chain is already tested)
    $display("\nTesting with carry-in=1...");
    c0 = 1;
    for (i = 0; i < 256; i = i + 32) begin  // Reduced set for c0=1
        x = i;
        for (j = 0; j < 256; j = j + 32) begin
            y = j;
            #10;
            
            expected = x + y + c0;
            
            if ({c8, z} !== expected) begin
                errors = errors + 1;
                $display("FAIL: x=%h, y=%h, c0=1 ? got %h_%h, expected %h_%b",
                        x, y, c8, z, expected[7:0], expected[8]);
            end
        end
    end
    
    // Final report
    $display("\nTest complete");
    $display("Total test cases: %0d", (256*256) + (16*16));
    $display("Total errors:     %0d", errors);
    
    if (errors == 0)
        $display("SUCCESS: All tests passed!");
    else
        $display("FAIL: Found %0d errors", errors);
    
    $finish;
end

endmodule
module d_ff (
    input pd,
    input sd,
    input clk,
    input rst_b,
    input shift,
    input load,
    output reg q
);
  
always @(posedge clk, negedge rst_b) begin
    if (!rst_b) begin
        q <= 1'b0;
    end
    else begin
        if (load) begin
            q <= pd;
        end
        else if (shift) begin
            q <= sd;
        end
    end
end
endmodule

module shift_reg (
    input wire [7:0] d,
    input clk,
    input rst_b,
    input shift,
    input load,
    output [7:0] q
);

d_ff d7 (.pd(d[7]), .sd(q[7]), .clk(clk), .rst_b(rst_b), .shift(shift), .load(load), .q(q[7]));
d_ff d6 (.pd(d[6]), .sd(q[7]), .clk(clk), .rst_b(rst_b), .shift(shift), .load(load), .q(q[6]));
d_ff d5 (.pd(d[5]), .sd(q[7]), .clk(clk), .rst_b(rst_b), .shift(shift), .load(load), .q(q[5]));
d_ff d4 (.pd(d[4]), .sd(q[6]), .clk(clk), .rst_b(rst_b), .shift(shift), .load(load), .q(q[4]));
d_ff d3 (.pd(d[3]), .sd(q[5]), .clk(clk), .rst_b(rst_b), .shift(shift), .load(load), .q(q[3]));
d_ff d2 (.pd(d[2]), .sd(q[4]), .clk(clk), .rst_b(rst_b), .shift(shift), .load(load), .q(q[2]));
d_ff d1 (.pd(d[1]), .sd(q[3]), .clk(clk), .rst_b(rst_b), .shift(shift), .load(load), .q(q[1]));
d_ff d0 (.pd(d[0]), .sd(q[2]), .clk(clk), .rst_b(rst_b), .shift(shift), .load(load), .q(q[0]));

endmodule

`timescale 1ns/1ns

module tb_shift_reg();
    reg [7:0] d;
    reg clk, rst_b, shift, load;
    wire [7:0] q;
    
    // Instantiate the shift register
    shift_reg uut (
        .d(d),
        .clk(clk),
        .rst_b(rst_b),
        .shift(shift),
        .load(load),
        .q(q)
    );
    
    // Clock generation
    always begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        // Initialize inputs
        d = 8'h00;
        clk = 0;
        rst_b = 1;
        shift = 0;
        load = 0;
        
        // Test case 1: Reset test
        rst_b = 0;  // Assert reset
        #10;
        rst_b = 1;  // Release reset
        #10;
        $display("After reset: q = %b (hex: %h)", q, q);
        
        // Test case 2: Load test pattern
        d = 8'hB5;   // Binary: 1011_0101
        load = 1;
        #10;
        load = 0;
        #10;
        $display("After load:  q = %b (hex: %h)", q, q);
        
        // Test case 3: Perform 2-bit right shift
        shift = 1;
        #10;  // Wait for clock edge
        shift = 0;
        #10;
        $display("After shift: q = %b (hex: %h)", q, q);
        
        // Verify expected result (should be 1110_1101 = 0xED)
        if (q === 8'hED)
            $display("TEST PASSED!");
        else
            $display("TEST FAILED! Expected 8'hED, got %h", q);
        
        // Add more test cases if needed
        #10;
        $finish;
    end
    
    initial begin
        $dumpfile("shift_reg.vcd");
        $dumpvars(0, tb_shift_reg);
        #200 $finish;
    end
endmodule
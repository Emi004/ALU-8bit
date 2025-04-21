`include "cu.v"
`include "au.v"

module alu (
    input clk,rst,
    input [1:0] select,
    input [7:0]A,B,
    output[15:0] result,
    output overflow,negative,zero,carry_out,done
);
    
    wire startadd,startsub,startmultiplier,startdiv;
    cu CU(.clk(clk),.rst(rst),.s(select),.startadd(startadd),.startsub(startsub),.startdiv(startdiv),.startmultiplier(startmultiplier));
    au AU(.clk(clk),.rst(rst),.A(A),.B(B),.startadd(startadd),.startsub(startsub),
        .startdiv(startdiv),.startmultiplier(startmultiplier),.result(result),
        .overflow(overflow),.negative(negative),.zero(zero),.carry_out(carry_out),
        .done(done)
    );

endmodule

`timescale 1ns/1ps
module alu_tb;

    // Inputs
    reg clk;
    reg rst;
    reg [1:0] select;
    reg [7:0] A;
    reg [7:0] B;
    
    // Outputs
    wire [15:0] result;
    wire overflow;
    wire negative;
    wire zero;
    wire carry_out;
    wire done;
    
    // Instantiate ALU
    alu uut (
        .clk(clk),
        .rst(rst),
        .select(select),
        .A(A),
        .B(B),
        .result(result),
        .overflow(overflow),
        .negative(negative),
        .zero(zero),
        .carry_out(carry_out),
        .done(done)
    );
    
    // Clock generation (100MHz)
    always #5 clk = ~clk;
    
// Add this to your testbench to monitor CU outputs
initial begin
    $monitor("Time=%0t: select=%b startadd=%b startsub=%b startmult=%b startdiv=%b",
             $time, select, 
             uut.CU.startadd, uut.CU.startsub, 
             uut.CU.startmultiplier, uut.CU.startdiv);
end

// Monitor adder status in testbench
initial begin
    $monitor("Time=%0t: addsub_result=%h done=%b",
             $time, uut.AU.addsub_result, done);
end

    initial begin
        // Initialize inputs
        clk = 0;
        rst = 1;
        select = 0;
        A = 0;
        B = 0;
        
        // Apply reset
        #20 rst = 0;
        #10;
        
        // Test addition
        $display("\nTesting Addition (5 + 10)");
        select = 2'b00;
        A = 8'd5;
        B = 8'd10;
        wait_for_completion();
        
        // Test subtraction
        $display("\nTesting Subtraction (20 - 8)");
        select = 2'b01;
        A = 8'd20;
        B = 8'd8;
        wait_for_completion();
        
        // Test multiplication
        $display("\nTesting Multiplication (6 * 7)");
        select = 2'b10;
        A = 8'd6;
        B = 8'd7;
        wait_for_completion();
        
        // Test division
        $display("\nTesting Division (25 / 4)");
        select = 2'b11;
        A = 8'd25;
        B = 8'd4;
        wait_for_completion();
        
        $display("\nALU Testbench Complete");
        $finish;
    end
    
    task wait_for_completion;
        begin
            // Wait for operation to start
            @(posedge uut.CU.startadd or 
              posedge uut.CU.startsub or 
              posedge uut.CU.startmultiplier or 
              posedge uut.CU.startdiv);
            
            // Wait for completion
            @(posedge done);
            $display("Result: %h (dec: %0d)", result, result);
            $display("Flags: OF=%b, NEG=%b, ZERO=%b, CO=%b", 
                    overflow, negative, zero, carry_out);
            #20;
        end
    endtask
    
endmodule
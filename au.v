`include "mlcla.v"
`include "srt2.v"
`include "newbooth.v"



module au (
    input[7:0]A,B,
    input clk,rst, startadd,startsub,startdiv,startmultiplier,
    output reg[15:0] result,
    output overflow,negative,zero,carry_out,
    //divisionBy0,
    output reg done
);
    wire[7:0]addsub_result,quotient,remainder;
    wire[15:0]product;
    wire mult_done,div_done;
    
    mlcla addsub(.x(A),.y(B),.start(startadd|startsub),.select(startsub),.c8(carry_out),.z(addsub_result),.overflow(overflow),.negative(negative),.zero(zero));
    newbooth multi(.multiplicand(A),.multiplier(B),.clk(clk),.rst(rst),.start(startmultiplier),.p(product),.done(mult_done));
    srt2 div(.dividend(A),.divisor(B),.clk(clk),.rst(rst),.quotient(quotient),.start(startdiv),.remainder(remainder),.done(div_done));

    reg start_mult_latched, start_div_latched;
    reg prev_startmultiplier, prev_startdiv;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        result <= 16'b0;
        done <= 0;
        start_mult_latched <= 0;
        start_div_latched <= 0;
        prev_startmultiplier <= 0;
        prev_startdiv <= 0;
    end else begin
        done <= 0;

        // Addition / Subtraction (combinational - no latching needed)
        if (startadd | startsub) begin
            result <= {{8{addsub_result[7]}}, addsub_result};
            done <= 1;
        end

        // Detect rising edge for multiplier
        prev_startmultiplier <= startmultiplier;
        if (~prev_startmultiplier & startmultiplier)
            start_mult_latched <= 1;
        if (start_mult_latched && mult_done) begin
            result <= product;
            done <= 1;
            start_mult_latched <= 0;
        end

        // Detect rising edge for divider
        prev_startdiv <= startdiv;
        if (~prev_startdiv & startdiv)
            start_div_latched <= 1;
        if (start_div_latched && div_done) begin
            result <= {quotient, remainder};
            done <= 1;
            start_div_latched <= 0;
        end
    end
end


endmodule




`timescale 1ns/1ps

module au_tb;
    // Inputs
    reg [7:0] A, B;
    reg clk, rst;
    reg startadd, startsub, startdiv, startmultiplier;
    
    // Outputs
    wire [15:0] result;
    wire overflow, negative, zero, carry_out, done;
    
    // Instantiate Unit Under Test
    au uut (
        .A(A),
        .B(B),
        .clk(clk),
        .rst(rst),
        .startadd(startadd),
        .startsub(startsub),
        .startdiv(startdiv),
        .startmultiplier(startmultiplier),
        .result(result),
        .overflow(overflow),
        .negative(negative),
        .zero(zero),
        .carry_out(carry_out),
        .done(done)
    );
    
    // Clock generation (100MHz)
    always #5 clk = ~clk;
    
    // Test control
    integer test_num = 0;
    integer error_count = 0;
    
    // Initialize waveform dump
    initial begin
        $dumpfile("au_wave.vcd");
        $dumpvars(0, au_tb);
    end
    
    task automatic verify;
        input [15:0] expected;
        input expected_overflow;
        input expected_negative;
        input expected_zero;
        begin
            test_num = test_num + 1;
            
            if (result !== expected) begin
                $display("Test %0d ERROR: Result mismatch! Got %h, expected %h",
                         test_num, result, expected);
                error_count = error_count + 1;
            end
            else if (overflow !== expected_overflow) begin
                $display("Test %0d ERROR: Overflow mismatch! Got %b, expected %b",
                         test_num, overflow, expected_overflow);
                error_count = error_count + 1;
            end
            else if (negative !== expected_negative) begin
                $display("Test %0d ERROR: Negative flag mismatch! Got %b, expected %b",
                         test_num, negative, expected_negative);
                error_count = error_count + 1;
            end
            else if (zero !== expected_zero) begin
                $display("Test %0d ERROR: Zero flag mismatch! Got %b, expected %b",
                         test_num, zero, expected_zero);
                error_count = error_count + 1;
            end
            else begin
                $display("Test %0d PASSED: Result=%h, OF=%b, NEG=%b, ZERO=%b",
                         test_num, result, overflow, negative, zero);
            end
        end
    endtask
    
    task automatic run_test;
        input [7:0] a_val, b_val;
        input add, sub, mul, div;
        input [15:0] expected;
        input exp_of, exp_neg, exp_zero;
        begin
            // Setup inputs
            @(negedge clk);
            A = a_val;
            B = b_val;
            startadd = add;
            startsub = sub;
            startmultiplier = mul;
            startdiv = div;
            
            // Wait for completion
            @(posedge done);
            
            // Verify results
            verify(expected, exp_of, exp_neg, exp_zero);
            
            // Clear operation signals
            @(negedge clk);
            startadd = 0;
            startsub = 0;
            startmultiplier = 0;
            startdiv = 0;
            #20;
        end
    endtask
    
    initial begin
        // Initialize
        clk = 0;
        rst = 1;
        startadd = 0;
        startsub = 0;
        startdiv = 0;
        startmultiplier = 0;
        #100;
        
        // Reset release
        rst = 0;
        #100;
        
        $display("\nStarting Arithmetic Unit Testbench\n");
        
        ////////////////////////////////////////////////////////////////////
        // Test Group 1: Addition/Subtraction
        ////////////////////////////////////////////////////////////////////
        
        // Test 1.1: Simple addition
        run_test(8'h30, 8'h12, 
                1, 0, 0, 0,  // add=1, others=0
                16'h0042,     // expected result
                0, 0, 0);     // flags: of, neg, zero
        
        // Test 1.2: Addition with overflow
        run_test(8'h7F, 8'h01,
                1, 0, 0, 0,
                16'hFF80,
                1, 1, 0);
        
        // Test 1.3: Simple subtraction
        run_test(8'h50, 8'h30,
                0, 1, 0, 0,
                16'h0020,
                0, 0, 0);
        
        // Test 1.4: Subtraction with negative result
        run_test(8'h30, 8'h50,
                0, 1, 0, 0,
                16'hFFE0,
                0, 1, 0);
        
        // Test 1.5: Subtraction with zero result
        run_test(8'h80, 8'h80,
                0, 1, 0, 0,
                16'h0000,
                0, 0, 1);
        
        ////////////////////////////////////////////////////////////////////
        // Test Group 2: Multiplication
        ////////////////////////////////////////////////////////////////////
        
        // Test 2.1: Simple multiplication
        run_test(8'h10, 8'h10,
                0, 0, 1, 0,
                16'h0100,
                0, 0, 0);
        
        // Test 2.2: Multiplication with negative result
        run_test(8'hF0, 8'h10,
                0, 0, 1, 0,
                16'hF100,
                0, 1, 0);
        
        ////////////////////////////////////////////////////////////////////
        // Test Group 3: Division
        ////////////////////////////////////////////////////////////////////
        
        // Test 3.1: Simple division
        run_test(8'h40, 8'h08,
                0, 0, 0, 1,
                16'h0800,  // quotient=8, remainder=0
                0, 0, 0);
        
        // Test 3.2: Division with remainder
        run_test(8'h43, 8'h08,
                0, 0, 0, 1,
                16'h0803,  // quotient=8, remainder=3
                0, 0, 0);
        
        // Final report
        #100;
        $display("\nTestbench completed");
        $display("Tests run: %0d", test_num);
        $display("Errors:    %0d", error_count);
        $finish;
    end
    
    // Monitor to track operations
    initial begin
        forever begin
            @(posedge clk);
            $display("Time=%0t: A=%h B=%h op=%b%b%b%b | result=%h done=%b flags=%b%b%b",
                     $time, A, B, startadd, startsub, startmultiplier, startdiv,
                     result, done, overflow, negative, zero);
        end
    end
endmodule
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

module srt2 (
    input [7:0] dividend, divisor,
    input clk, start, rst,
    output reg [7:0] quotient, remainder,
    output reg done,divisionBy0
);

// === State Definitions ===
localparam 
    IDLE            = 3'b000,
    SHIFT_NORMALIZE = 3'b001,
    DIVIDE_LOOP     = 3'b010,
    FINAL_CORRECTION= 3'b011,
    SHIFT_BACK      = 3'b100,
    DONE            = 3'b101,
    WAITADDER       = 3'b110;

reg [2:0] state;
reg [3:0] shift_count, count;
reg [8:0] A;
reg [7:0] Q, M;
reg [8:0] next_A;
reg [7:0] next_Q;

reg [8:0] adder_A, adder_B;
reg adder_select;
wire [8:0] adder_result;
_9bitadder adder (
    .x(adder_A),
    .y(adder_B),
    .select(adder_select),
    .z(adder_result),
    .c9(),
    .overflow(),
    .negative(),
    .zero()
);



always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        A <= 0;
        Q <= 0;
        M <= 0;
        shift_count <= 0;
        count <= 0;
        done <= 0;
        divisionBy0 <= 0;
    end else begin
        case (state)
            IDLE: begin
                done <= 0;
                if (start) begin
                    if (divisor == 0) begin
                        quotient <= 8'hFF;
                        remainder <= 8'hFF;
                        done <= 1;
                        divisionBy0 <= 1;
                        state <= IDLE;
                    end else begin
                        A <= 0;
                        Q <= dividend;
                        M <= divisor;
                        shift_count <= 0;
                        count <= 0;
                        divisionBy0 <= 0;
                        
                        state <= SHIFT_NORMALIZE;
                    end
                end
            end

            SHIFT_NORMALIZE: begin
                if (M[7] != 1'b1) begin
                    A <= {A[7:0], Q[7]};
                    Q <= {Q[6:0], 1'b0};
                    M <= {M[6:0], 1'b0};
                    shift_count <= shift_count + 1;
                end else begin
                    state <= DIVIDE_LOOP;
                end
            end

            DIVIDE_LOOP: begin
                if (count < 8) begin
                    case (A[8:6])
                        3'b000,3'b111: begin
                            // No operation, just shift
                            next_A = {A[7:0], Q[7]};
                            next_Q = {Q[6:0], 1'b0};
                            A <= next_A;
                            Q <= next_Q;
                            count <= count + 1;
                        end
                        3'b011,3'b010,3'b001: begin
                            // Subtract and set quotient bit to 1
                            adder_A <= {A[7:0], Q[7]};
                            adder_B <= {1'b0, M};
                            adder_select <= 1'b1;
                            next_Q = {Q[6:0], 1'b1};
                            state <= WAITADDER;
                        end
                        default: begin
                            // Add and set quotient bit to 0
                            adder_A <= {A[7:0], Q[7]};
                            adder_B <= {1'b0, M};
                            adder_select <= 1'b0;
                            next_Q = {Q[6:0], 1'b0};
                            state <= WAITADDER;
                        end
                    endcase
                end else begin
                    state <= FINAL_CORRECTION;
                end
            end

            WAITADDER: begin
                A <= adder_result;
                Q <= next_Q;
                count <= count + 1;
                state <= DIVIDE_LOOP;
            end

            FINAL_CORRECTION: begin
                if (A[8]) begin
                    adder_A <= A;
                    adder_B <= {1'b0, M};
                    adder_select <= 1'b0; // Add M to restore
                    next_Q = Q - 1;
                    state <= WAITADDER;
                end else begin
                    state <= SHIFT_BACK;
                end
            end

            SHIFT_BACK: begin
                if (shift_count > 0) begin
                    A <= {1'b0, A[8:1]};
                    shift_count <= shift_count - 1;
                end else begin
                    state <= DONE;
                end
            end

            DONE: begin
                quotient <= Q;
                remainder <= A[7:0];
                done <= 1;
                state <= IDLE;
            end
        endcase
    end
end
endmodule

`timescale 1ns / 1ps

module srt2_tb;

    // Inputs
    reg [7:0] dividend;
    reg [7:0] divisor;
    reg clk;
    reg start;
    reg rst;

    // Outputs
    wire [7:0] quotient;
    wire [7:0] remainder;
    wire done;

    // Instantiate the Unit Under Test (UUT)
    srt2 uut (
        .dividend(dividend),
        .divisor(divisor),
        .clk(clk),
        .start(start),
        .rst(rst),
        .quotient(quotient),
        .remainder(remainder),
        .done(done)
    );

    // Clock generation (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test procedure
    initial begin
        // Initialize Inputs
        rst = 1;
        start = 0;
        dividend = 0;
        divisor = 0;

        // Reset the system
        #10;
        rst = 0;
        #10;

        // Test Case 1: Normal division (200 / 10 = 20 R 0)
        dividend = 200;
        divisor = 10;
        start = 1;
        #10;
        start = 0;

        // Wait until done
        wait(done);
        $display("Test 1: %d / %d = %d R %d", dividend, divisor, quotient, remainder);
        #20;

        // Test Case 2: Division with remainder (57 / 5 = 11 R 2)
        dividend = 57;
        divisor = 5;
        start = 1;
        #10;
        start = 0;

        wait(done);
        $display("Test 2: %d / %d = %d R %d", dividend, divisor, quotient, remainder);
        #20;

        // Test Case 3: Division by zero (should not break, but result is undefined)
        dividend = 100;
        divisor = 0;
        start = 1;
        #10;
        start = 0;

        wait(done);
        $display("Test 3: %d / %d = %d R %d (Division by zero!)", dividend, divisor, quotient, remainder);
        #20;

        // Test Case 4: Maximum values (255 / 255 = 1 R 0)
        dividend = 255;
        divisor = 255;
        start = 1;
        #10;
        start = 0;

        wait(done);
        $display("Test 4: %d / %d = %d R %d", dividend, divisor, quotient, remainder);
        #20;

        // Test Case 5: Small numbers (1 / 1 = 1 R 0)
        dividend = 1;
        divisor = 1;
        start = 1;
        #10;
        start = 0;

        wait(done);
        $display("Test 5: %d / %d = %d R %d", dividend, divisor, quotient, remainder);
        #20;

        $finish;
    end

endmodule
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

module newbooth(
    input [7:0] multiplicand, multiplier,
    input clk, rst,start,
    output reg[15:0] p,
    output reg done
);

reg [8:0] A;        
reg [8:0] Q;        
reg [8:0] M;        
reg [2:0] count;    

parameter IDLE = 2'b00;
parameter COMPUTE = 2'b01;
parameter FINISH = 2'b10;
parameter LOAD = 2'b11;
reg [1:0] state;

wire [8:0] adder_out;
wire adder_cout;
reg adder_select;
reg [8:0] adder_input;

_9bitadder adder (
    .x(A),
    .y(adder_input),
    .select(adder_select),
    .c9(adder_cout),
    .z(adder_out),
    .overflow(),    // Not used in multiplier
    .negative(),    // Not used in multiplier
    .zero()        // Not used in multiplier
);

always @(posedge clk, posedge rst) begin

    if(rst)begin
        state <= IDLE;
        A <= 9'd0;
        Q <= 9'd0;
        M <= 9'd0;
        done <= 1'b0;
        count <= 3'd0;
        p <= 16'd0;
        adder_select <= 1'b0;
        adder_input <= 9'd0;
    end 
    else begin
        case (state)
            IDLE: begin
                done <= 1'b0;
                if(start)begin
                
                
                // Initialize registers
                A <= 9'd0;
                Q <= {multiplier, 1'b0};  // Q is multiplier with Q-1 bit
                M <= {multiplicand[7], multiplicand}; // Sign-extended
                count <= 3'd0;
                state <= LOAD;
                end
                
            end
            
            LOAD: begin

                case (Q[2:0])
                    3'b000, 3'b111: begin
                        // No operation (0*M)
                        adder_input <= 9'd0;
                        adder_select <= 1'b0; // Add 0 (NOP)
                    end
                    3'b001, 3'b010: begin
                        // Add M
                        adder_input <= M;
                        adder_select <= 1'b0; // Add M
                    end
                    3'b011: begin
                        // Add 2M
                        adder_input <= {M[7], M[7:0], 1'b0}; // 2*M with sign extension
                        adder_select <= 1'b0; // Add 2M
                    end
                    3'b100: begin
                        // Subtract 2M
                        adder_input <= {M[7], M[7:0], 1'b0}; // 2*M with sign extension
                        adder_select <= 1'b1; // Subtract 2M
                    end
                    3'b101, 3'b110: begin
                        // Subtract M
                        adder_input <= M;
                        adder_select <= 1'b1; // Subtract M
                    end
                endcase
                state <= COMPUTE;

            end

            COMPUTE: begin
                // Update A with adder result
                A <= adder_out;
                
                if (count < 3'd4) begin  // Need 4 iterations for 8-bit operands
                    count <= count + 1;
                    done <= 1'b0;
                    state <= FINISH;
                end else begin
                    p <= {A[7:0], Q[8:1]};
                    done <= 1'b1;
                    state <= IDLE;
                end
            end
            
            FINISH: begin
                // Perform arithmetic right shift 2 bits
                A <= {A[8], A[8], A[8:2]};             
                Q <= {A[1], A[0], Q[8:2]};   
                state <= LOAD;
            end
            
        endcase
    end

end

endmodule

module newbooth_tb;

reg clk;
reg rst;
reg [7:0] multiplicand;
reg [7:0] multiplier;

// Outputs
wire [15:0] product;
wire done;

newbooth uut(
    .multiplicand(multiplicand),
    .multiplier(multiplier),
    .clk(clk),
    .rst(rst),
    .p(product),
    .done(done)
);

localparam CLK_PERIOD = 40;
localparam CLK_CYCLES = 20;
localparam RST_PULSE = 5;



initial begin
    multiplicand = 8'b00001101;
    multiplier = 8'b00011100;
end

initial begin
    clk = 1'b0;
    repeat (2*CLK_CYCLES) #(CLK_PERIOD/2) clk = ~clk;
end

initial begin
    rst = 1'b1;
    #(RST_PULSE) rst = 1'b0;
end

initial begin
    repeat (2*CLK_CYCLES) #CLK_PERIOD;
    $finish;
end
initial begin
    
    wait(done);
    @(posedge clk);
    $display("Multiplicand: %d, Multiplier: %d, Product: %d", multiplicand, multiplier, product);
    if (product !== multiplicand * multiplier) begin
        $display("Test failed: Expected %d, Got %d", multiplicand * multiplier, product);
    end else begin
        $display("Test passed!");
    end
    $finish;
end

endmodule
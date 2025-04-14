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
    input[7:0]dividend, divisor,
    input clk, start, rst,
    output reg [7:0] quotient, remainder,
    output reg done
);
    reg [8:0]A;
    reg[7:0] Q_prim, Q, M;
    reg[2:0]count1,count2;

    parameter IDLE = 3'b000, SHIFT0 = 3'b001, LOAD = 3'b010, CALC = 3'b011, ADDQPRIM = 3'b100, SUBQ = 3'b101, CHECKCNT1 = 3'b110, DONE = 3'b111;
    reg [2:0] state;

reg addqload = 1'b1;
reg [8:0]adder_inputA, adder_inputB;
reg select;
wire [8:0]adder_out;

_9bitadder adder(
    .x(adder_inputA),
    .y(adder_inputB),
    .select(select),
    .z(adder_out),
    .c9(),
    .negative(),
    .overflow(),
    .zero()
);

always @(posedge clk or posedge rst)begin
    if(rst)begin
        Q <= 8'b0;
        A <= 9'b0;
        M <= 8'b0;
        Q_prim <= 8'b0;
        count1 <= 3'b0;
        count2 <= 3'b0;
        done <= 1'b0;

    end
    else begin
        case (state)
            IDLE:begin
            A<= 9'b0;
            Q <= dividend;
            M <= divisor;
            count1 <= 3'd0;
            count2 <= 3'd0;
            Q_prim<= 8'b0;
            done <= 1'b0;
            state <= SHIFT0;
            end
            
            SHIFT0:begin
                if(M[7]==1'b0)begin
                    A<=A[7:0];
                    Q<=Q;
                    M[7:1]<=M;
                    M[0]<=1'b0;
                    count1<=count1+1;
                    state <= SHIFT0;
                end
                else begin
                    state<= LOAD;
                end
            end
            
            LOAD:begin 
                case(A[8:6])
                    3'b000,3'b111:begin
                        A<=A[7:0];
                        Q[7:1]<=Q;
                        Q[0]<=1'b0;
                        Q_prim[7:1]<=Q_prim[6:0];
                        Q_prim[0]<=1'b0;
                        adder_inputA <= A;
                        adder_inputB<=8'b0;
                        select<=1'b0;
                        
                    end
                    
                    3'b001,3'b010,3'b011:begin
                        A<=A[7:0];
                        Q[7:1]<=Q;
                        Q[0]<=1'b1;
                        Q_prim[7:1]<=Q_prim[6:0];
                        Q_prim[0]<=1'b0;
                        select<=1'b1;
                        adder_inputA <= A;
                        adder_inputB<=M;
                    end
                    
                    3'b100,3'b101,3'b110:begin
                        A<=A[7:0];
                        Q[7:1]<=Q;
                        Q[0]<=1'b0;
                        Q_prim[7:1]<=Q_prim[6:0];
                        Q_prim[0]<=1'b1;
                        select<=1'b0;
                        adder_inputA <= A;
                        adder_inputB<=M;
                    end
                endcase
                state<= CALC;
            end
            
            CALC:begin
            A<=adder_out;
            if (count2<3'd7)begin
                count2<=count2+1;
                state<=LOAD;
            end
            else begin
                if(A[8]==1'b1)begin
                adder_inputA <= A;
                adder_inputB <= M;
                select<=1'b0;
                state<=ADDQPRIM;
            end else begin
                state<=SUBQ;
            end
                
            end

            end
            
            ADDQPRIM:begin  // reg addqload = 1'b1
                if (addqload == 1'b1)begin
                    A<=adder_out;
                    select<=1'b0;
                    adder_inputA <= Q_prim;
                    adder_inputB <= 1'b1;
                    state <= ADDQPRIM;
                    addqload = 1'b0;
                end
                else begin
                    Q_prim <= adder_out[7:0];
                    state<=SUBQ;
                end
            end
            
            SUBQ:begin
                adder_inputA <= Q;
                adder_inputB<=Q_prim;
                select<=1'b1;
                state<=CHECKCNT1;
            end
            
            CHECKCNT1:begin
                Q<=adder_out[7:0];
                if(count1==0) begin
                    A[7:0]<=A[8:1];
                    A[8]<=1'b0;
                    count1<=count1-1;
                    state<=CHECKCNT1;
                end
                else begin
                    state<=DONE;
                end
            end
            
            DONE:begin
                done<=1'b1;
                quotient<=Q;
                remainder<=A;
                state<=IDLE;

            end
            
            
            
        endcase
    
    end

end



endmodule

module srt2_tb;

reg [7:0]dividend, divisor;
reg clk, start, rst;
wire [7:0] quotient, remainder;
wire done;

srt2 uut(
    .dividend(dividend),
    .divisor(divisor),
    .clk(clk),
    .start(start),
    .rst(rst),
    .quotient(quotient),
    .remainder(remainder),
    .done(done)
);

parameter CLK_CYCLES = 20;
parameter CLK_PERIOD = 20;
parameter RST_PULSE = 5;

initial begin
    dividend = 8'b00111011;
    divisor = 8'b00000110;
end

initial begin
    clk = 1'b0;
    repeat(CLK_CYCLES) #(CLK_PERIOD/2) clk = ~clk;
end

initial begin
    rst = 1'b1;
    #(RST_PULSE) rst = 1'b0;
end

initial begin
    wait(done);
    #(CLK_PERIOD);
    $finish;
end

endmodule
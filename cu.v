module cu (
    input done,
    input clk,
    input rst,
    input [1:0] s,
    output reg startadd,        // Starts addition/subtraction module
    output reg startsub,        // 0=addition, 1=subtraction
    output reg startmultiplier, // Starts multiplier
    output reg startdiv         // Starts divider
);

parameter IDLE = 2'b00, 
          START_OP = 2'b01, 
          WAIT_DONE = 2'b10;

reg [1:0] state;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        startadd <= 0;
        startsub <= 0;
        startmultiplier <= 0;
        startdiv <= 0;
    end else begin
        // Default all start signals to 0 unless triggered
        startadd <= 0;
        startsub <= 0;
        startmultiplier <= 0;
        startdiv <= 0;

        case (state)
            IDLE: begin
                case (s)
                    2'b00: begin startadd <= 1; startsub <= 0; state <= WAIT_DONE; end
                    2'b01: begin startadd <= 1; startsub <= 1; state <= WAIT_DONE; end
                    2'b10: begin startmultiplier <= 1; state <= WAIT_DONE; end
                    2'b11: begin startdiv <= 1; state <= WAIT_DONE; end
                endcase
            end
            WAIT_DONE: begin
                if (done) state <= IDLE;
            end
        endcase
    end
end

endmodule

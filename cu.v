module cu (
    input clk,
    input rst,
    input [1:0] s,
    output reg startadd,
    output reg startsub,
    output reg startmultiplier,
    output reg startdiv
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        startadd <= 0;
        startsub <= 0;
        startmultiplier <= 0;
        startdiv <= 0;
    end
    else begin
        startadd <= 0;
        startsub <= 0;
        startmultiplier <= 0;
        startdiv <= 0;
        
        case(s)
            2'b00: begin
                startadd <= 1;
                startsub <= 0;
            end
            2'b01: begin
                startadd <= 1;
                startsub <= 1;
            end
            2'b10: begin
                startmultiplier <= 1;
            end
            2'b11: begin
                startdiv <= 1;
            end
            default: begin
                startadd <= 0;
                startsub <= 0;
                startmultiplier <= 0;
                startdiv <= 0;
            end
        endcase
    end
end

endmodule
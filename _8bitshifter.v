module dff (
    input clk,      
    input d,       
    output reg q    
);
    
    always @(posedge clk) begin
        q <= d;
    end
    
endmodule


module _8bitshifter(
    input clk,fill,shift_dir, 
    input [2:0]s,
    input [7:0]d,
    output reg [7:0]q
);
always @(posedge clk ) begin
    
    // 0 for left shift
    if(shift_dir==0)begin
            case (s)
                3'd0: q<=d;
                3'd1: q<={d[6:0],fill};
                3'd2: q<={d[5:0],{2{fill}}}; 
                3'd3: q<={d[4:0],{3{fill}}};
                3'd4: q<={d[3:0],{4{fill}}};
                3'd5: q<={d[2:0],{5{fill}}};
                3'd6: q<={d[1:0],{6{fill}}};
                3'd7: q<={d[0],{7{fill}}};
                default: q<=d;
            endcase

    end
    // 1 for right shift
    else if(shift_dir==1)begin
            case (s)
                3'd0: q<=d;
                3'd1: q<={fill,d[7:1]};
                3'd2: q<={{2{fill}},d[7:2]};
                3'd3: q<={{3{fill}},d[7:3]};
                3'd4: q<={{4{fill}},d[7:4]};
                3'd5: q<={{5{fill}},d[7:5]};
                3'd6: q<={{6{fill}},d[7:6]};
                3'd7: q<={{7{fill}},d[7]};
                default: q<=d;
            endcase
    end
end


endmodule

// module tb_8bitshifter;
//     reg clk, fill, shift_dir;
//     reg [2:0] s;
//     reg [7:0] d;
//     wire [7:0] q;

//     _8bitshifter uut (
//         .clk(clk),
//         .fill(fill),
//         .shift_dir(shift_dir),
//         .s(s),
//         .d(d),
//         .q(q)
//     );

//     // Clock generation (100 MHz)
//     initial begin
//         clk = 0;
//         forever #5 clk = ~clk;
//     end

//     // Test cases
//     initial begin
//         // Initialize
//         shift_dir = 0;  // Start with LEFT shift
//         fill = 1;
//         d = 8'b10101010;
//         s = 0;

//         // Test LEFT shifts
//         #10 s = 1;      // Shift left by 1, fill=1
//         #10 s = 3;       // Shift left by 3
//         #10 s = 7; fill = 0;  // Max left shift, fill=0

//         // Test RIGHT shifts
//         #10 shift_dir = 1; s = 1; fill = 1;  // Right shift by 1
//         #10 s = 4;       // Right shift by 4
//         #10 s = 7; fill = 0;  // Max right shift, fill=0

//         // Change input data
//         #10 d = 8'b11110000;
//         #10 s = 2;       // Right shift by 2
//         #10 shift_dir = 0; s = 2; fill = 1;  // Left shift by 2

//         #10 $finish;
//     end

//     // Monitor results
//     initial begin
//         $monitor("Time=%0t | dir=%s | s=%d | fill=%b | d=%b | q=%b",
//                  $time,
//                  shift_dir ? "RIGHT" : "LEFT",
//                  s,
//                  fill,
//                  d,
//                  q);
//     end
// endmodule
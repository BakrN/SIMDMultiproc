// Could be replaced with floating point multiplier later 
module#(parameter WIDTH = 32) multiplier(
    in0 , 
    in1 , 
    out
); 
    input  [WIDTH-1:0] in0;
    input  [WIDTH-1:0] in1;
    output [WIDTH-1:0] out; 
    assign out = in0 * in1;
endmodule

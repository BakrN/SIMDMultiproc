// could be replaced with floating point adder 
module #(parameter WIDTH=32) adder(
    in0, 
    in1,
    out 
    ); 
    input  signed [WIDTH-1:0] in0;
    input  signed [WIDTH-1:0] in1;
    output signed [WIDTH-1:0] out; 
    assign out = in0 + in1;

endmodule 

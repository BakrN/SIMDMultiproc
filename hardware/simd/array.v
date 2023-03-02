// SIMD adder/multiplier array 
module simd_arr#(parameter width = 4, parameter operand_width = 32) (  
    opcode, // ADD , MUL , sub (in1 - in2)
    i_in1,  
    i_in2, 
    o_res
); 
    localparam ow = operand_width; 
    localparam w = width;
    localparam op_add = 2'b00 ; 
    localparam op_mul = 2'b01 ; 
    localparam op_sub = 2'b10 ; 

    input wire [(w*ow-1):0] i_in1 ;
    input wire [(w*ow-1):0] i_in2 ;
    input wire [1:0] opcode; 
    output wire [(w*ow-1):0] o_res ;
    
    wire [ow-1:0] w_adder_out [w-1:0]; 
    wire [ow-1:0] w_mul_out [w-1:0]; 
    
    assign w_adder_out[3] = (!opcode[1]) ? (i_in1[(w*ow-1):((w-1)*ow)]     + i_in2[(w*ow-1):((w-1)*ow)]) : (i_in1[(w*ow-1):((w-1)*ow)] - i_in2[(w*ow-1):((w-1)*ow)]) ; 
    assign w_adder_out[2] = (!opcode[1]) ? (i_in1[((w-1)*ow-1):((w-2)*ow)] + i_in2[((w-1)*ow-1):((w-2)*ow)]) : (i_in1[((w-1)*ow-1):((w-2)*ow)] - i_in2[((w-1)*ow-1):((w-2)*ow)]) ; 
    assign w_adder_out[1] = (!opcode[1]) ? (i_in1[((w-2)*ow-1):((w-3)*ow)] + i_in2[((w-2)*ow-1):((w-3)*ow)]) : (i_in1[((w-2)*ow-1):((w-3)*ow)] - i_in2[((w-2)*ow-1):((w-3)*ow)]) ; 
    assign w_adder_out[0] = (!opcode[1]) ? (i_in1[((w-3)*ow-1):((w-4)*ow)] + i_in2[((w-3)*ow-1):((w-4)*ow)]) : (i_in1[((w-3)*ow-1):((w-4)*ow)] - i_in2[((w-3)*ow-1):((w-4)*ow)]) ; 


    assign w_mul_out[3]   = i_in1[(w*ow-1):((w-1)*ow)]     * i_in2[(w*ow-1):((w-1)*ow)]     ;  
    assign w_mul_out[2]   = i_in1[((w-1)*ow-1):((w-2)*ow)] * i_in2[((w-1)*ow-1):((w-2)*ow)] ; 
    assign w_mul_out[1]   = i_in1[((w-2)*ow-1):((w-3)*ow)] * i_in2[((w-2)*ow-1):((w-3)*ow)] ; 
    assign w_mul_out[0]   = i_in1[((w-3)*ow-1):((w-4)*ow)] * i_in2[((w-3)*ow-1):((w-4)*ow)] ; 

    assign o_res = (opcode==op_mul) ? {w_mul_out[3], w_mul_out[2], w_mul_out[1], w_mul_out[0]} : 
                                    {w_adder_out[3], w_adder_out[2], w_adder_out[1], w_adder_out[0]} ;   
                                    


endmodule 
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
    localparam op_sub = 2'b01 ; 
    localparam op_mul = 2'b10 ; 
    

    input  logic [(w*ow-1):0] i_in1 ; 
    input  logic [(w*ow-1):0] i_in2 ;    
    input  logic [1:0] opcode;   
    output logic [(w*ow-1):0] o_res ;  
    
    logic signed [ow-1:0] w_adder_out [w-1:0];  
    logic signed [ow-1:0] w_mul_out   [w-1:0]; 
    // defining operands
    logic signed [ow-1:0] operands_0 [w-1:0];  
    logic signed [ow-1:0] operands_1 [w-1:0]; 

     
    generate  
        for (genvar i = w-1 ;  i>=0; i--) begin 
            assign operands_0[i] = i_in1[((i+1)*ow-1):((i)*ow)] ;
            assign operands_1[i] = i_in2[((i+1)*ow-1):((i)*ow)] ;
        end
    endgenerate
    generate 
        for (genvar i = 0 ; i < w ; i++)begin 
            always_comb begin 
                if (opcode == op_add) begin 
                    w_adder_out[i] = operands_0[i] + operands_1[i]; 
                end else begin 
                    w_adder_out[i] = operands_0[i] - operands_1[i]; 
                end 
            end
        end
    endgenerate 
    
    assign w_mul_out[3]   = i_in1[(w*ow-1):((w-1)*ow)]     * i_in2[(w*ow-1):((w-1)*ow)]     ;  
    assign w_mul_out[2]   = i_in1[((w-1)*ow-1):((w-2)*ow)] * i_in2[((w-1)*ow-1):((w-2)*ow)] ; 
    assign w_mul_out[1]   = i_in1[((w-2)*ow-1):((w-3)*ow)] * i_in2[((w-2)*ow-1):((w-3)*ow)] ; 
    assign w_mul_out[0]   = i_in1[((w-3)*ow-1):((w-4)*ow)] * i_in2[((w-3)*ow-1):((w-4)*ow)] ; 

    assign o_res = (opcode==op_mul) ? {w_mul_out[3], w_mul_out[2], w_mul_out[1], w_mul_out[0]} : 
                                    {w_adder_out[3], w_adder_out[2], w_adder_out[1], w_adder_out[0]} ;   
                                    


endmodule 
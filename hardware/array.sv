// MAC unit / adder unit .
// option to have seperate adder and mac unit vs having a multiplixer to adder
// inputs
// For now 3x3
module array#(parameter UNIT_SIZE= 32) (
opcode, // Add / sub / matmul 
i_in1,  // matrix or vector
i_in2,  // vector
o_res
);
input  [1:0] opcode ; // 0 = add , 1 = sub , 2 = matmul
input  [UNIT_SIZE*5-1:0] i_in1; // at least for 3x3 muls
input  [UNIT_SIZE*5-1:0] i_in2;
output [UNIT_SIZE*5-1:0] o_res;
// What we need: matmul unit and adder unit
logic signed [UNIT_SIZE-1:0] vec        [3];
logic signed [2:0][UNIT_SIZE-1:0] mat   [3];
logic signed [UNIT_SIZE-1:0] adder[6];

assign {vec[0] , vec[1], vec[2]} = i_in2[UNIT_SIZE*5-1:2*UNIT_SIZE];
always_comb begin
    for (int row = 0 ; row < 3 ; row++) begin
        for (int col = 0 ; col < 3 ; col++) begin
            mat[col][row] = i_in1[(2 - row + col)*UNIT_SIZE+:UNIT_SIZE];
        end
    end
end

// addition/sub/acc unit (8 adders)
always_comb begin
    if(opcode == 0) begin // add
        for (int i = 0 ; i < 5 ; ++i)begin
            adder[i] = i_in1[(5-i)*UNIT_SIZE-1-:UNIT_SIZE] + i_in2[(5-i)*UNIT_SIZE-1-:UNIT_SIZE];
        end
        adder[5] = 0 ;
    end else if (opcode==1) begin // sub
        for (int i = 0 ; i < 5 ; ++i) begin
            adder[i] = i_in1[(5-i)*UNIT_SIZE-1-:UNIT_SIZE] - i_in2[(5-i)*UNIT_SIZE-1-:UNIT_SIZE];
        end
        adder[5] = 0 ;
    end else begin // mat mul
    // matrix mul result will be stored in adder_out [0] , [1] , [2]
    //                                               Y0    Y1     Y2
    // display mat
        adder[3] = mul_int[0][0] + mul_int[0][1];
        adder[0] = adder[3] + mul_int[0][2]; // Y0
        adder[4] = mul_int[1][0] + mul_int[1][1] ; // answer is here for 
        adder[1] =  adder[4]+ mul_int[1][2]; // Y1 ;
        adder[5] = mul_int[2][0] + mul_int[2][1] ; 
        adder[2] =  adder[5]+ mul_int[2][2]; // Y2 ;
    end
end



// multiply unit (element-wise)
logic signed [2:0][UNIT_SIZE-1:0] mul_int [3];
always_comb begin
    mul_int[0][0] = vec[0] * mat[0][0];
    mul_int[0][1] = vec[1] * mat[0][1];
    mul_int[0][2] = vec[2] * mat[0][2];
    mul_int[1][0] = vec[0] * mat[1][0];
    mul_int[1][1] = vec[1] * mat[1][1];
    mul_int[1][2] = vec[2] * mat[1][2];
    mul_int[2][0] = vec[0] * mat[2][0];
    mul_int[2][1] = vec[1] * mat[2][1];
    mul_int[2][2] = vec[2] * mat[2][2];
end
generate
for (genvar i = 0 ; i < 5 ; i++) begin
    assign o_res[(5-i)*UNIT_SIZE-1:(5-i-1)*UNIT_SIZE]= adder[i] ;
end
endgenerate



endmodule

// Modules capable of doing 2x2 and 3x3 (for now) (might increase size) matrix-vec multiplication using MACs.
// For now it's 3x3
module  toep_mmul#(parameter UNIT_SIZE=8)( i_clk  , i_rstn , i_en   , i_data , o_data ) ; 
input i_clk  ;
input i_rstn ;
input i_en   ;
input  logic i_mat [8*UNIT_SIZE-1:0];   // flattened 3x3 toep 8 elements
input  logic i_vec [3*UNIT_SIZE-1:0];   // 3x1 vector
output logic o_data[3*UNIT_SIZE-1:0];   // 3x1 vector
logic [UNIT_SIZE-1:0] vec [2:0];
logic [2:0][UNIT_SIZE-1:0] mat [2:0];  
logic [UNIT_SIZE-1:0] result [2:0];
assign {vec[0], vec[1], vec[2]} = i_vec;
generate 
for (genvar row = 0 ; row < 3 ; row++) begin 
    for (genvar col = 0 ; col < 3 ; col++) begin 
        assign mat[i][j] = i_mat[2 - row + col];
    end
end
endgenerate

always_comb begin 
    result[0] = mat[0][0] * vec[0] + mat[0][1] * vec[1] + mat[0][2] * vec[2];
    result[1] = mat[1][0] * vec[0] + mat[1][1] * vec[1] + mat[1][2] * vec[2];
    result[2] = mat[2][0] * vec[0] + mat[2][1] * vec[1] + mat[2][2] * vec[2];
end
assign o_data = {result[0], result[1], result[2]};
endmodule 

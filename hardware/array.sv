`include "arithmetic_unit.sv"  
module simd_array #(parameter UNIT_SIZE= 32, parameter WIDTH=4) (
i_clk,  // can be used to work on faster clock 
i_rstn, 
i_op, // add , sub , MAC
i_a,  
i_b,  
i_run ,  
o_valid, 
o_res  
);

input i_clk ; 
input i_run; 
input i_rstn; 
input [1:0]  i_op; 
input  logic [UNIT_SIZE-1:0] i_a   [WIDTH] ; 
input  logic [UNIT_SIZE-1:0] i_b   [WIDTH] ; 
logic [UNIT_SIZE-1:0] res [WIDTH] ;  
output logic [WIDTH-1:0] [UNIT_SIZE-1:0] o_res; 
output o_valid ;

always_comb begin 
    for (int i = 0 ; i < WIDTH; i++) begin 
        o_res[i] = res[i] ; 
    end
end
logic [WIDTH-1:0] valid;
assign o_valid = &valid;  
logic en, prev_en  ; 
always @(posedge i_clk) begin 
    prev_en <= i_run ; 
end 
assign en = i_run && !prev_en ;  
generate 
    for (genvar i = 0 ; i < WIDTH ; i++) begin
        a_unit #(.WIDTH(UNIT_SIZE) ) u_unit (
            .i_clk (i_clk), 
            .i_rstn(i_rstn), 
            .i_a   (i_a[i]), 
            .i_b   (i_b[i]), 
            .i_op  (i_op), // 0: a + b, 1: a-b: 2: MAC
            .i_en  (en),
            .o_res (res[i]) , 
            .o_valid (valid[i])
        ) ;  
    end
endgenerate 


endmodule

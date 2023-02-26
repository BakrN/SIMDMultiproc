// round robin arbitration 
// store next 
module arbiter#(parameter N = 4)(
    i_clk, 
    i_rstn, 
    i_req, 
    o_grant
) ; 
    input  i_clk ; 
    input  i_rstn; 
    input [N-1:0] i_req ;
    output [N-1:0] o_grant ;

    wire [N-1:0] r_mask_grant ;  


endmodule 
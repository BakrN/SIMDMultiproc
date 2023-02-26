/// contains arbiter and scratchpad 
module shared_mem #(parameter COUNT = 4, 
                    parameter BUS_SIZE = 128) (
    i_clk , 
    i_rstn, 
    i_req , 
    i_data, 
    o_data, 
    o_grant
) ; 
    // Arbiter 
    input i_clk   ;  
    input i_rstn  ;  
    input [COUNT-1:0] i_req   ; 
    input [BUS_SIZE-1:0] i_data ;
    input [BUS_SIZE-1:0] o_data ;
    output [COUNT-1:0] o_grant;  
    // mem info 
    



endmodule ; 
`include "defines.sv"
`include "fifo.sv"
// Need to add mechanism to confirm to cpu that command was written 
module cmd_queue#(parameter DEPTH =16, parameter WIDTH=248 ) (
    i_clk       ,
    i_rstn      ,
    i_read      ,
    i_wr_ctrl   ,   
    i_data_ctrl ,
    o_data      ,
    o_fifo_full ,
    o_fifo_empty,
    o_issuer_valid
) ;   
/* -------------------------------- IO Ports -------------------------------- */
    input  i_clk                   ; 
    input  i_rstn                  ; 
    input  i_read                  ; 
    input i_wr_ctrl                ;   
    input cmd_t i_data_ctrl        ; 
    output cmd_t o_data            ;  
    output o_fifo_full             ;  
    output o_fifo_empty            ;  
    output o_issuer_valid            ; 
    output busy                    ; 

    fifo #( 
        .WIDTH ( $bits(cmd_t) ),
        .DEPTH ( 16  ))
     u_fifo (
        .i_clk                     ( i_clk                      ),
        .i_rstn                    ( i_rstn                     ),
        .i_read                    ( i_read                     ),
        .i_write                   ( i_wr_ctrl                  ),
        .i_data                    ( i_data_ctrl                ), 
        .o_data                    ( o_data                     ),
        .o_fifo_full               ( o_fifo_full                ),
        .o_fifo_empty              ( o_fifo_empty               )
    );

endmodule 
`include "defines.svh"
`include "fifo.sv"

module cmd_queue#(parameter NUM_PORTS=2 , parameter DEPTH =16, parameter WIDTH=248 ) (
    i_clk       ,
    i_rstn      ,
    i_read      ,
    i_write     ,
    i_data      ,
    o_data      ,
    o_fifo_full ,
    o_fifo_empty              
) ; 
/* -------------------------------- IO Ports -------------------------------- */
    input  i_clk                   ; 
    input  i_rstn                  ; 
    input  i_read                  ; 
    input  [NUM_PORTS-1:0] i_write                 ; 
    input cmd_t i_data [NUM_PORTS-1:0]                 ; 
    output cmd_t o_data                 ;  
    output o_fifo_full            ;  
    output o_fifo_empty           ;  

// fifo logic and module instantiation
    logic fifo_write ; 
    cmd_t fifo_data; 
    assign fifo_write = |i_write ;

    assign fifo_data = (i_write[0]) ? i_data[0] : i_data[1];
fifo #(
    .WIDTH ( $bits(cmd_t) ),
    .DEPTH ( 16  ))
 u_fifo (
    .i_clk                     ( i_clk                      ),
    .i_rstn                    ( i_rstn                     ),
    .i_read                    ( i_read                     ),
    .i_write                   ( fifo_write ),
    .i_data                    ( fifo_data ), 
    .o_data                    ( o_data                     ),
    .o_fifo_full               ( o_fifo_full                ),
    .o_fifo_empty              ( o_fifo_empty               )
);

endmodule 
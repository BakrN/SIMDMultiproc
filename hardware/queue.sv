`include "defines.sv"
`include "fifo.sv"

module cmd_queue#(parameter DEPTH =16, parameter WIDTH=248 ) (
    i_clk       ,
    i_rstn      ,
    i_read      ,
    i_wr_ctrl   ,   
    i_wr_issuer , 
    i_data_ctrl ,
    i_data_issuer,
    o_data      ,
    o_fifo_full ,
    o_fifo_empty,
    o_issuer_ack
) ;   
/* -------------------------------- IO Ports -------------------------------- */
    input  i_clk                   ; 
    input  i_rstn                  ; 
    input  i_read                  ; 
    input i_wr_ctrl                ;   
    input i_wr_issuer              ;  
    input cmd_t i_data_ctrl        ; 
    input cmd_t i_data_issuer      ;   
    output cmd_t o_data            ;  
    output o_fifo_full             ;  
    output o_fifo_empty            ;  
    output o_issuer_ack            ; 
    output busy                    ; 
/* ------------------- FIFO logic and Module Instantiation ------------------ */
    logic fifo_write     ; 
    cmd_t fifo_data      ; 
    logic [1:0] state    ; 
    logic select ; // 0 for ctrl 1 for issuer
    localparam IDLE     = 0  ; 
    localparam ACK= 1  ; 
    localparam WR_ISSUER= 2  ; 
    localparam WR_CTRL  = 3  ;   
    assign fifo_write = state[1];
    assign fifo_data = (select) ? i_data_issuer : i_data_ctrl;   

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
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin 
            state <= IDLE;  
        end else begin 
            if (i_wr_ctrl ) begin 
                select <= 0 ; 
                state <= WR_CTRL;  
            end else if (i_wr_issuer) begin 
                select <= 1 ; 
                state <= WR_ISSUER; 
            end
            case (state)  
               WR_CTRL: begin 
                state <= IDLE ;
               end
               WR_ISSUER: begin 
                state <= IDLE ;
               end
               ACK: begin 
                state <= IDLE ; 
               end 
            endcase
        end
    end

endmodule 
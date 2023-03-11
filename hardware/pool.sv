`include "defines.sv"
`include "proc.sv"
module pool( 
    i_instr   ,   
    i_clk     , 
    i_rstn    , 
    i_en      , 
    i_grant   , 
    i_valid   , 
    o_req     , 
    o_finish  ,  
    o_busy    , 
    o_ack     , 
    o_id 
); 

input instr_t i_instr   [`PROC_COUNT-1:0]; 
input i_clk   ; 
input i_rstn   ; 
input [`PROC_COUNT-1:0]  i_en      ;
input [`PROC_COUNT-1:0]  i_grant   ; 
input [`PROC_COUNT-1:0]  i_valid   ; 
output [`PROC_COUNT-1:0] o_req     ; 
output [`PROC_COUNT-1:0] o_finish  ;
output [`PROC_COUNT-1:0] o_busy    ; 
output [`PROC_COUNT-1:0] o_ack     ; 
output cmd_id_t o_id [`PROC_COUNT-1:0] ;
genvar i ; 
generate
 for (i = 0 ; i < `PROC_COUNT ; i = i + 1)  begin 
        proc  u_proc (
            .i_instr                 ( i_instr  [i]        ),
            .i_clk                   ( i_clk               ),
            .i_rstn                  ( i_rstn              ),
            .i_en                    ( i_en      [i]       ),
            .i_grant                 ( i_grant   [i]       ),
            .i_valid                 ( i_valid   [i]       ),
            .o_id                    ( o_id      [i]       ),
            .o_finish                ( o_finish  [i]       ),
            .o_req                   ( o_req     [i]       ),
            .o_busy                  ( o_busy    [i]       ),
            .o_ack                   ( o_ack     [i]       )
        );
    end
endgenerate

endmodule
`include "defines.sv"
`include "proc.sv"
module pool( 
    i_instr   ,   
    i_clk     , 
    i_rstn    , 
    i_en      , 
    i_grant_rd   , 
    i_grant_wr   , 
    i_valid   , 
    o_req_rd     , 
    o_req_wr , 
    o_finish  ,  
    o_busy    , 
    o_ack     , 
    i_data   ,
    o_addr ,
    o_data , 
    o_wr_size 
); 

input instr_t i_instr   ; 
input i_clk   ; 
input i_rstn   ; 
input [127:0 ] i_data ; 

input [`PROC_COUNT-1:0]  i_en      ;
input [`PROC_COUNT-1:0]  i_grant_rd  ; 
input [`PROC_COUNT-1:0]  i_grant_wr  ; 
input [`PROC_COUNT-1:0]  i_valid   ; 
output [`PROC_COUNT-1:0] o_req_rd     ; 
output [`PROC_COUNT-1:0] o_req_wr     ; 
output [`PROC_COUNT-1:0] o_finish  ;
output [`PROC_COUNT-1:0] o_busy    ; 
output [`PROC_COUNT-1:0] o_ack     ; 
output logic [127:0] o_data [`PROC_COUNT-1:0]; 
output addr_t o_addr [`PROC_COUNT-1:0] ;  
output logic [2:0] o_wr_size [`PROC_COUNT-1:0] ;  
genvar i ; 
generate
 for (i = 0 ; i < `PROC_COUNT ; i = i + 1)  begin 
        proc  u_proc (
    .i_instr                 (              i_instr              ),
    .i_clk                   (              i_clk                 ),
    .i_rstn                  (              i_rstn                ),
    .i_en                    (              i_en                 [i] ),
    .i_grant_rd              (              i_grant_rd           [i] ),
    .i_grant_wr              (              i_grant_wr           [i] ),
    .i_valid                 (              i_valid              [i] ),
    .i_data                  (              i_data               ),
    .o_finish                (              o_finish             [i] ),
    .o_req_rd                (              o_req_rd             [i] ),
    .o_req_wr                (              o_req_wr             [i] ),
    .o_busy                  (              o_busy               [i] ),
    .o_ack                   (              o_ack                [i] ),
    .o_addr                  (              o_addr               [i] ), 
    .o_wr_size               (              o_wr_size            [i] ),
    .o_data                  (              o_data               [i] )
);
    end
endgenerate

endmodule
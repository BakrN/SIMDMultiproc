`include "defines.sv"
`include "proc.sv"
module pool( 
    i_cmd ,
    i_clk     ,
    i_rstn    ,
    i_en      ,
    i_grant_rd   ,
    i_grant_wr   ,
    o_req_rd  ,
    o_req_wr ,
    o_finish  ,
    o_busy    ,
    i_data   ,
    o_addr ,
    o_data , 
    o_wr_en , 
    o_wr_size 
    `ifdef DEBUG
    , o_states
    `endif
);

input cmd_info_t i_cmd;
input i_clk   ;
input i_rstn   ;
input [`BUS_W-1:0 ] i_data ;

input [`PROC_COUNT-1:0]  i_en      ;
input [`PROC_COUNT-1:0]  i_grant_rd  ;
input [`PROC_COUNT-1:0]  i_grant_wr  ;
output [`PROC_COUNT-1:0] o_req_rd     ;
output [`PROC_COUNT-1:0] o_req_wr     ;
output [`PROC_COUNT-1:0] o_finish  ;
output [`PROC_COUNT-1:0] o_busy    ;
output [`PROC_COUNT-1:0] o_wr_en    ;

output logic [`BUS_W-1:0] o_data [`PROC_COUNT-1:0];
output addr_t o_addr [`PROC_COUNT-1:0] ;
output logic [2:0] o_wr_size [`PROC_COUNT-1:0] ;

logic [`BUS_W-1:0] test_out ;
logic [2:0] test_wr  ;
`ifdef DEBUG
    output logic [`PROC_COUNT-1:0][3:0] o_states  ; 
`endif
//
generate
 for (genvar i = 0 ; i < `PROC_COUNT ; i++)  begin 
        proc  u_proc (
    .i_cmd             (    i_cmd      ),
    .i_clk             (    i_clk      ),
    .i_rstn            (    i_rstn     ),
    .i_en              (    i_en      [i] ),
    .i_grant_rd        (    i_grant_rd[i] ),
    .i_grant_wr        (    i_grant_wr[i] ),
    .i_data            (    i_data        ),
    .o_finish          (    o_finish [i] ),
    .o_req_rd          (    o_req_rd [i] ),
    .o_req_wr          (    o_req_wr [i] ),
    .o_busy            (    o_busy   [i] ),
    .o_addr            (    o_addr[i] ), 
    .o_wr_size         (    o_wr_size[i] ), 
    .o_wr_en           (    o_wr_en[i] ),
    .o_data            (    o_data[i] ) 
    `ifdef DEBUG 
        , .o_state( o_states[i] )
    `endif 
);
    end
endgenerate

//        proc  u_proc (
//    .i_instr           (    i_instr         ),
//    .i_clk             (    i_clk           ),
//    .i_rstn            (    i_rstn         ),
//    .i_en              (    i_en      [3] ),
//    .i_grant_rd        (    i_grant_rd[3] ),
//    .i_grant_wr        (    i_grant_wr[3] ),
//    .i_valid           (    i_valid   [3] ),
//    .i_data            (    i_data        ),
//    .o_finish          (    o_finish [3] ),
//    .o_req_rd          (    o_req_rd [3] ),
//    .o_req_wr          (    o_req_wr [3] ),
//    .o_busy            (    o_busy   [3] ),
//    .o_addr            (    o_addr[3] ), 
//    .o_wr_size         (test_wr),
//    .o_data            (test_out)
//);



always_ff @(posedge i_clk) begin : blockName
//    $display("PROC[3] outputs: %h, with size: %h, at addr: %h",  test_out, test_wr, o_addr[3]);
end

endmodule

/// contains arbiter and scratchpad
`include "arbiter.sv"
`include "mem.sv"
`include "encoder.sv"
module shared_mem #(parameter PORT_COUNT = 4,
                    parameter BUS_SIZE = 160,
                    parameter MEM_SIZE = 1024, 
                    parameter UNIT_SIZE = 32, 
                    parameter ADDR_SIZE = 24
                    ) (
    i_clk       , 
    i_rstn      ,  
    i_proc_addr ,  
    o_proc_rd   ,
    i_proc_wr   ,
    i_wr_size   , 
    i_req_rd    ,  
    i_req_wr    , 
    o_grant_rd  , 
    o_grant_wr
) ;
    /* -------------------------------- IO Ports -------------------------------- */
    input i_clk   ;
    input i_rstn  ;
    // Arbiter 
    input [PORT_COUNT-1:0] i_req_rd , i_req_wr;
    output [PORT_COUNT-1:0] o_grant_rd, o_grant_wr;
    // mem info
    output logic [BUS_SIZE-1:0] o_proc_rd ;
    input logic [BUS_SIZE-1:0] i_proc_wr [PORT_COUNT-1:0];
    input logic [2:0] i_wr_size [PORT_COUNT-1:0];
    input addr_t i_proc_addr [PORT_COUNT-1:0];   // read addresses of all processors 
    logic [BUS_SIZE-1:0] rd_data;
    logic [BUS_SIZE-1:0] wr_data;
    logic [2:0] wr_size ;
    logic wr_en ;
    addr_t wr_addr;
    addr_t rd_addr;
    /* -------------------------- Module Instantiation -------------------------- */
    arbiter#(.N_REQ(PORT_COUNT))  rd_arbiter(
    .i_clk    (             i_clk     ),
    .i_rst_n  (             i_rstn   ),
    .i_req    (  i_req_rd             ),
    .o_grant  (  o_grant_rd           )
    );
    arbiter#(.N_REQ(PORT_COUNT))  wr_arbiter(
    .i_clk    ( i_clk                 ),
    .i_rst_n  ( i_rstn               ),
    .i_req    ( i_req_wr              ),
    .o_grant  ( o_grant_wr            )
    );
    assign wr_en = |o_grant_wr;
    assign wr_addr = i_proc_addr[enc_wr];
    assign wr_size = i_wr_size[enc_wr];
    assign wr_data = i_proc_wr[enc_wr];
    assign rd_addr = i_proc_addr[enc_rd];
    mem_mod#(.DEPTH(MEM_SIZE),.BLOCK_SIZE(BUS_SIZE/UNIT_SIZE), .SIZE(UNIT_SIZE), .ADDR_SIZE(ADDR_SIZE))  u_mem (
    .i_clk                   ( i_clk     ),
    .i_addr_w                ( wr_addr   ),
    .i_data_w                ( wr_data   ),
    .i_wr_size               (  wr_size  ),
    .i_wr_en                 ( wr_en     ),
    .i_addr_r                ( rd_addr   ),
    .o_data                  ( o_proc_rd   )
    );
    logic [$clog2(PORT_COUNT)-1:0] enc_wr,enc_rd ;
    encoder #(.WIDTH ( PORT_COUNT ))
     u_grant_wr (
        .i_in  ( o_grant_wr ),
        .o_enc(  enc_wr  )
    );
    encoder #(.WIDTH ( PORT_COUNT ))
     u_grant_rd (
        .i_in  ( o_grant_rd ),
        .o_enc(  enc_rd  )
    );

endmodule

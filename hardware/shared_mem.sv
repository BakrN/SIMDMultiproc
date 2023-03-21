/// contains arbiter and scratchpad 
`include "arbiter.sv"
`include "mem.sv"
`include "defines.sv"
`include "encoder.sv"
module shared_mem #(parameter COUNT = 4, 
                    parameter BUS_SIZE = 128) (
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
    input [COUNT-1:0] i_req_rd , i_req_wr; 
    output [COUNT-1:0] o_grant_rd, o_grant_wr;  
    // mem info 
    output logic [BUS_SIZE-1:0] o_proc_rd ;  
    input logic [BUS_SIZE-1:0] i_proc_wr [COUNT-1:0]; 
    input logic [2:0] i_wr_size [COUNT-1:0];  
    input addr_t i_proc_addr [COUNT-1:0];   // read addresses of all processors 
    logic [BUS_SIZE-1:0] rd_data; 
    logic [BUS_SIZE-1:0] wr_data;  
    logic [2:0] wr_size ; 
    logic wr_en ; 
    addr_t wr_addr; 
    addr_t rd_addr; 
    /* -------------------------- Module Instantiation -------------------------- */
    arbiter#(COUNT)  rd_arbiter(
    .i_clk    (             i_clk     ),
    .i_rst_n  (             i_rstn   ),
    .i_req    (  i_req_rd             ),
    .o_grant  (  o_grant_rd           )
    );
    arbiter#(COUNT)  wr_arbiter( 
    .i_clk    ( i_clk                 ),
    .i_rst_n  ( i_rstn               ),
    .i_req    ( i_req_wr              ),
    .o_grant  ( o_grant_wr            )
    ); 
    assign wr_en = |o_grant_wr; 
   
    assign wr_addr = i_proc_addr[enc_wr];  
    assign wr_size = i_wr_size[enc_wr];  
    assign rd_addr = i_proc_addr[enc_rd];  
    mem  u_mem ( 
    .i_clk                   ( i_clk     ),
    .i_addr_w                ( wr_addr   ),
    .i_data_w                ( wr_data   ),
    .i_wr_size               (  wr_size    ),
    .i_wr_en                 ( wr_en     ),
    .i_addr_r                ( rd_addr   ), 
    .o_data                  ( o_proc_rd   )
    );
    logic [$clog2(COUNT)-1:0] enc_wr ; 
    encoder #(.WIDTH ( COUNT ))
     u_grant_wr (
        .i_in  ( o_grant_wr ),
        .o_enc(  enc_wr  )
    ); 
    logic [$clog2(COUNT)-1:0] enc_rd ;  
    encoder #(.WIDTH ( COUNT ))
     u_grant_rd ( 
        .i_in  ( o_grant_rd),
        .o_enc(  enc_rd  )
    );  
    
endmodule ; 

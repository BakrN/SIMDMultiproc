/// contains arbiter and scratchpad 
`include "arbiter/arbiter.sv"
`include "mem.sv"
`include "defines.sv"

module shared_mem #(parameter COUNT = 4, 
                    parameter BUS_SIZE = 128) (
    i_clk , 
    i_rstn, 
    i_proc_addr ,  
    o_proc_rd ,
    i_proc_wr ,
    i_req_rd ,  
    i_req_wr , 
    rd_data, 
    rd_addr, 
    wr_data,  
    wr_addr, 
    o_grant_rd, 
    o_grant_wr
) ; 
    /* -------------------------------- IO Ports -------------------------------- */
    input i_clk   ;  
    input i_rstn  ;   
    // Arbiter 
    input [COUNT-1:0] i_req_rd , i_req_wr; 
    output [COUNT-1:0] o_grant_rd, o_grant_wr;  
    // mem info 
    output[BUS_SIZE-1:0] o_proc_rd [COUNT-1:0];  
    input [BUS_SIZE-1:0] i_proc_wr [COUNT-1:0]; 
    input addr_t i_rd_addr [COUNT-1:0];   // read addresses of all processors
    input addr_t i_wr_addr [COUNT-1:0];   // write addresses of all processors
    logic [BUS_SIZE-1:0] rd_data; 
    logic [BUS_SIZE-1:0] wr_data;  
    
    logic wr_en ; 
    /* -------------------------- Module Instantiation -------------------------- */
    arbiter#(COUNT)  rd_arbiter(
    .i_clk    (             i_clk     ),
    .i_rst_n  (             i_rst_n   ),
    .i_req    (  i_req_rd             ),
    .o_grant  (  o_grant_rd           )
    );
    arbiter#(COUNT)  wr_arbiter( 
    .i_clk    ( i_clk                 ),
    .i_rst_n  ( i_rst_n               ),
    .i_req    ( i_req_wr              ),
    .o_grant  ( o_grant_wr            )
    ); 
    assign wr_en = |o_grant_wr; 
    assign o_proc_rd[enc_rd] = rd_data; 
    assign o_proc_wr[enc_wr] = wr_data; 
    assign wr_addr = i_wr_addr[enc_wr];  
    assign rd_addr = i_rd_addr[enc_rd];  
    mem  u_mem ( 
    .i_clk                   ( i_clk     ),
    .i_addr_w                ( wr_addr   ),
    .i_data_w                ( wr_data   ),
    .i_wr_en                 ( wr_en     ),
    .i_addr_r                ( rd_addr   ), 
    .o_data                  ( rd_data   )
    );
    logic [$clog2(COUNT)-1:0] enc_wr ; 
    encoder #(.WIDTH ( COUNT ))
     u_grant_wr (
        .i_in  ( o_grant_wr ),
        .o_enc(  enc_wr  );
    ); 
    logic [$clog2(COUNT)-1:0] enc_rd ;  
    encoder #(.WIDTH ( COUNT ))
     u_grant_rd ( 
        .i_in  ( o_grant_rd),
        .o_enc(  enc_rd  );
    ); 
    
endmodule ; 

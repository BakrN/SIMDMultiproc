// Top module without queue incorporated yet 
`include "issuer.sv"
`include "pool.sv"
`include "shared_mem.sv"

module top (
    i_clk, 
    i_rstn, 
    queue_cmd ,
    issuer_rd_queue, 
    queue_empty, 
    finished_task 
) ;  
input i_clk; 
input i_rstn; 
input cmd_t queue_cmd ;
input logic queue_empty ; 
output finished_task ;  

// issuer Outputs 
logic [`PROC_COUNT-1:0] issuer_en_proc; 
logic [`PROC_COUNT-1:0] issuer_ack_proc;
instr_t issuer_instr;
output logic   issuer_rd_queue;
issuer  u_issuer (
    .i_clk                               (   i_clk            ),
    .i_rstn                              (   i_rstn           ),
     // cmd queue ports
    .i_cmd                               (   queue_cmd        ),
    .i_empty_queue                       (   queue_empty      ),         
    .o_rd_queue                          (   issuer_rd_queue  ), 
    // pool ports
    .i_busy_proc                         (   pool_busy        ),
    .i_finish_proc                       (   pool_finish      ),
    .o_en_proc                           (   issuer_en_proc   ),
    .o_ack_proc                          (   issuer_ack_proc  ), 
    .o_instr                             (   issuer_instr     ),
    // io
    .o_finished_task    (     finished_task     ) 
);

// pool Outputs
logic[`PROC_COUNT-1:0]  pool_req_rd;
logic[`PROC_COUNT-1:0]  pool_req_wr;
logic[`PROC_COUNT-1:0]  pool_finish;
logic[`PROC_COUNT-1:0]  pool_busy;
logic[`PROC_COUNT-1:0]  pool_wr_en;
wire [`BUS_W-1:0] pool_data [`PROC_COUNT-1:0];
wire [$bits(addr_t)-1:0]pool_addr [`PROC_COUNT-1:0];
wire[2:0] pool_wr_size [`PROC_COUNT-1:0];





pool  u_pool (
    .i_instr            (     issuer_instr      ),
    .i_clk              (     i_clk             ),
    .i_rstn             (     i_rstn            ),
    .i_data             (     mem_proc_rd       ),
    .i_en               (     issuer_en_proc    ),
    .i_grant_rd         (     mem_grant_rd      ),
    .i_grant_wr         (     mem_grant_wr      ),
    .i_valid            (     issuer_ack_proc   ),
    .o_req_rd           (     pool_req_rd       ),
    .o_req_wr           (     pool_req_wr       ),
    .o_finish           (     pool_finish       ),
    .o_busy             (     pool_busy         ),
    .o_data             (     pool_data         ),
    .o_addr             (     pool_addr         ),
    .o_wr_en            (     pool_wr_en        ),
    .o_wr_size          (     pool_wr_size      )
    
);

// shared_mem Outputs
logic [`PROC_COUNT-1:0]    mem_grant_rd;
logic [`PROC_COUNT-1:0]    mem_grant_wr;
logic [`BUS_W-1:0] mem_proc_rd ;

shared_mem #(
        .PORT_COUNT(`PROC_COUNT) ,
        .BUS_SIZE ( `BUS_W   ),
        .MEM_SIZE (`MEM_SIZE), 
        .UNIT_SIZE(`USIZE),
        .ADDR_SIZE ($bits(addr_t)) 
    )
    u_shared_mem (
    .i_clk          ( i_clk          ),
    .i_rstn         ( i_rstn         ),
    .i_req_rd       ( pool_req_rd    ),
    .i_req_wr       ( pool_req_wr    ),
    .i_proc_wr      ( pool_data      ),
    .i_wr_size      ( pool_wr_size   ), 
    .i_wr_en        ( pool_wr_en     ),
    .i_proc_addr    ( pool_addr      ),
    .o_grant_rd     ( mem_grant_rd   ), 
    .o_grant_wr     ( mem_grant_wr   ),
    .o_proc_rd      ( mem_proc_rd    )
);

endmodule 

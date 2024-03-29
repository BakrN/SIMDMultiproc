// Top module without queue incorporated yet 
 
`include "issuer.sv"
`include "pool.sv"
`include "shared_mem.sv"
module top (
    i_clk, 
    i_rstn, 
    queue_cmd ,
    queue_ack , 
    issuer_rd_queue, 
    issuer_wr_queue, 
    issuer_cmd
) ;  
input i_clk; 
input i_rstn; 
input cmd_t queue_cmd ;
input logic queue_ack; // for issuer writebacks
// issuer Outputs 
logic [`PROC_COUNT-1:0] issuer_en_proc; 
logic [`PROC_COUNT-1:0] issuer_ack_proc;
instr_t issuer_instr;
output logic   issuer_rd_queue;
output logic   issuer_wr_queue;
output cmd_t   issuer_cmd;
issuer  u_issuer (
    .i_clk                               (        i_clk              ),
    .i_rstn                              (        i_rstn             ),
    .i_ack_queue                         (        queue_ack          ),
    .i_busy_proc                         (        pool_busy       ),
    .i_finish_proc                       (        pool_finish      ),
    .i_ack_proc                          (        pool_ack         ),
    .i_cmd                               (        queue_cmd          ),
    .o_en_proc                           (        issuer_en_proc     ),
    .o_ack_proc                          (        issuer_ack_proc    ), 
    .o_instr                             (        issuer_instr       ),
    .o_rd_queue                          (        issuer_rd_queue    ),
    .o_wr_queue                          (        issuer_wr_queue    ),
    .o_cmd                               (        issuer_cmd         )
);
// pool Outputs
logic[`PROC_COUNT-1:0]  pool_req_rd;
logic[`PROC_COUNT-1:0]  pool_req_wr;
logic[`PROC_COUNT-1:0]  pool_finish;
logic[`PROC_COUNT-1:0]  pool_busy;
logic[`PROC_COUNT-1:0]  pool_ack;
logic [127:0] pool_data [`PROC_COUNT-1:0];
addr_t pool_addr [`PROC_COUNT-1:0];
logic [2:0] pool_wr_size [`PROC_COUNT-1:0];

pool  u_pool (
    .i_instr                                  (     issuer_instr        ),
    .i_clk                                    (     i_clk               ),
    .i_rstn                                   (     i_rstn              ),
    .i_data                                   (     mem_proc_rd       ),
    .i_en                                     (     issuer_en_proc      ),
    .i_grant_rd                               (     mem_grant_rd        ),
    .i_grant_wr                               (     mem_grant_wr        ),
    .i_valid                                  (     issuer_ack_proc   ),
    .o_req_rd                                 (     pool_req_rd         ),
    .o_req_wr                                 (     pool_req_wr         ),
    .o_finish                                 (     pool_finish         ),
    .o_busy                                   (     pool_busy           ),
    .o_ack                                    (     pool_ack            ),
    .o_data                                   (     pool_data           ),
    .o_addr                                   (     pool_addr           ),
    .o_wr_size                                (     pool_wr_size        )
);
// shared_mem Outputs
localparam BUS_SIZE = 128; 
logic [`PROC_COUNT-1:0]    mem_grant_rd;
logic [`PROC_COUNT-1:0]    mem_grant_wr;
logic [BUS_SIZE-1:0] mem_proc_rd ;

shared_mem #(
    .BUS_SIZE ( BUS_SIZE))
 u_shared_mem (
    .i_clk          ( i_clk          ),
    .i_rstn         ( i_rstn         ),
    .i_req_rd       ( pool_req_rd       ),
    .i_req_wr       ( pool_req_wr       ),
    .i_proc_wr      ( pool_data      ),
    .i_wr_size      ( pool_wr_size   ),
    .i_proc_addr    ( pool_addr      ),
    .o_grant_rd                                  ( mem_grant_rd   ), 
    .o_grant_wr                                  ( mem_grant_wr   ),
    .o_proc_rd  ( mem_proc_rd    )
);

endmodule 
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


`ifdef DEBUG 
logic [`PROC_COUNT-1:0][3:0] states; 
`endif


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
    `ifdef DEBUG
    , .o_states            (     states           )
    `endif
    
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
`ifdef DEBUG
    // collect information about each processor in pool 
    int state_s[`PROC_COUNT-1:0][8:0];
    int cycle_count ;
    always_ff @(posedge i_clk or negedge i_rstn) begin 
        if (!i_rstn) begin 
            for (int i = 0 ; i < `PROC_COUNT; i++) begin
                for (int j = 0 ; j < 9 ; j++) begin 
                    state_s[i][j] = 0 ; 
                end
            end
            cycle_count = 0 ; 
        end
        else if (finished_task && queue_empty) begin 
            $display("Total cycles: %0d", cycle_count);
            for (int i = 0  ; i < `PROC_COUNT ; i++) begin 
                // print out the statistics collected by each processor
                $display("Processor %d: ", i);
                $display("  Idle: %0.2f%", state_s[i][0]*100/cycle_count);
                $display("  ld1:  %0.2f%", state_s[i][1]*100/cycle_count);
                $display("  ld2:  %0.2f%", state_s[i][2]*100/cycle_count);
                $display("  set_info: %0.2f", state_s[i][3]*100/cycle_count);
                $display("  store: %0.2f", state_s[i][4]*100/cycle_count);
                $display("  Fetch1: %0.2f", state_s[i][5]*100/cycle_count);
                $display("  Fetch2: %0.2f", state_s[i][6]*100/cycle_count);
                $display("  Write: %0.2f", state_s[i][7]*100/cycle_count);
                $display("  Finished: %0.2f", state_s[i][8]*100/cycle_count);
            end
        end else begin 
            for (int index =  0; index < `PROC_COUNT ; index++) begin 
                state_s[index][states[index]] = state_s[index][states[index]]+1;  
            end
            cycle_count++ ;
        end
    end
`endif

endmodule 

`include "top.sv"
`timescale 1ns/1ps
`ifndef CMD_SIZE
`define CMD_SIZE 3
`endif
module tb_top() ;
parameter T = 10 ;
// top Inputs
logic i_clk;
logic i_rstn;
cmd_t nxt_cmd;
logic queue_empty;
logic   issuer_rd_queue;
// top Outputs
logic finished_task; 

top  u_top (
    .i_clk                    ( i_clk                     ),
    .i_rstn                   ( i_rstn                    ),
    .queue_cmd                ( nxt_cmd),
    .queue_empty              ( queue_empty     ),
    .issuer_rd_queue          ( issuer_rd_queue ),
    .finished_task            ( finished_task)
);
// cmd queue 
fifo#(
    .WIDTH($bits(cmd_t)), 
    .DEPTH(2**$clog2(`CMD_SIZE))
    ) u_cmd_queue (
    .i_clk ( i_clk   ) , 
    .i_rstn( 1 )  , 
    .i_read( issuer_rd_queue   ) , 
    .i_write( 0   ), 
    .i_data(  0  ) , 
    .o_data(  nxt_cmd  ) , 
    .o_fifo_empty ( queue_empty  ) 
    ) ;
initial begin
    forever begin
        i_clk = 0 ;
        #(T/2) ;
        i_clk = 1 ;
        #(T/2) ;
    end
end

initial begin 
   $dumpfile("sim/tb_top.vcd");
   $dumpvars(0, u_top);
   $dumpvars(1, u_top.u_pool);
end
// In this test I will just stall if there is a dependency 
int mem_file, init_mem_file  ;
initial begin
    // Load initial mem 
    $readmemh("py/tests/shared_mem.txt",u_top.u_shared_mem.u_mem.r_mem);
    init_mem_file = $fopen("py/tests/init_sim_mem.txt", "w");
    for (int i = 0 ; i < `MEM_SIZE; i++) begin
        $fdisplay(init_mem_file,"%h",u_top.u_shared_mem.u_mem.r_mem[i]);
    end
    $fclose(init_mem_file);

    $display("shared mem loaded");
    $readmemb("py/tests/cmd_queue.txt",u_cmd_queue.memory);
    u_cmd_queue.readPtr =  0;
    u_cmd_queue.writePtr = `CMD_SIZE ;
    u_cmd_queue.o_count = `CMD_SIZE;
    $display("cmd queue loaded, cmd bits: %d", $bits(cmd_t));
    
    // reset 
    i_rstn = 0 ;
    #T ;
    i_rstn = 1 ;
    #T ;
    $display("is queue empty? %d", queue_empty);
    while (!queue_empty) begin
        if(issuer_rd_queue) begin
            //$display("cmd: %b", nxt_cmd);
        end
        #T ; 
    end
    $display("is queue empty? %d", queue_empty);

    while (!finished_task) begin
        #T ;
    end
    mem_file = $fopen("py/tests/sim_mem.txt", "w");
    for (int i = 0 ; i < `MEM_SIZE; i++) begin
        $fdisplay(mem_file,"%h",u_top.u_shared_mem.u_mem.r_mem[i]);
    end
    $fclose(mem_file);
    $finish ; 
end
endmodule



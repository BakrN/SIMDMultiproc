`include "top.sv"
`timescale 1ns/1ps
`ifndef CMD_SIZE
`define CMD_SIZE 1000
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
   $dumpvars(1, tb_top);
end
cmd_t cmd_queue [`CMD_SIZE-1:0] ; 
reg [31:0] result_mem [`MEM_SIZE-1:0] ;
// In this test I will just stall if there is a dependency 
int mem_file ;
initial begin
    // Load initial mem 
    $readmemh("py/shared_mem.txt",u_top.u_shared_mem.u_mem.r_mem);
    $display("shared mem loaded");
    $readmemh("py/valid_mem.txt",result_mem);
    $display("valid mem loaded");
    $readmemb("py/cmd_queue.txt",cmd_queue);
    $display("cmd queue loaded");
    // reset 
    i_rstn = 0 ;
    #T ;
    i_rstn = 1 ;
    #T ;
    queue_empty = 0 ;
    for (int i = 0 ; i < `CMD_SIZE; i++) begin
        nxt_cmd = cmd_queue[i]; 
        $display("cmd %d: %h",i,nxt_cmd); 
        while(!issuer_rd_queue) begin
            #T ;
        end
    end
    queue_empty  = 1;
    #(100*T) ; // wait for issuer ot finish
    mem_file = $fopen("tests/sim_mem.txt", "w");
    for (int i = 0 ; i < `MEM_SIZE; i++) begin
        $fdisplay(mem_file,"%h\n",u_top.u_shared_mem.u_mem.r_mem[i]);
    end
    $fclose(mem_file);
end
endmodule



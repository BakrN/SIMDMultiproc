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
// In this test I will just stall if there is a dependency 
int mem_file ;
initial begin
    // Load initial mem 
    $readmemh("py/tests/shared_mem.txt",u_top.u_shared_mem.u_mem.r_mem);
    $display("shared mem loaded");
    $readmemb("py/tests/cmd_queue.txt",cmd_queue);
    $display("cmd queue loaded, cmd bits: %d", $bits(cmd_t));
    
    // reset 
    i_rstn = 0 ;
    #T ;
    i_rstn = 1 ;
    #T ;
    queue_empty = 0 ;
    nxt_cmd = cmd_queue[0] ;  
    while (!issuer_rd_queue) begin
        #T ;
    end
    #T ;
    $display("cmd %d: %b",0,nxt_cmd); 
    for (int i =1 ;i< 2 ; i++) begin
        nxt_cmd = cmd_queue[i];  
        $display("cmd %d: %b",i,nxt_cmd); 
        while(!issuer_rd_queue) begin
            #T ;
        end
        #T ; 
    end
    $finish ;
    queue_empty  = 1;
    while (!finished_task) begin
        #T ;
    end
    mem_file = $fopen("tests/sim_mem.txt", "w");
    for (int i = 0 ; i < `MEM_SIZE; i++) begin
        $fdisplay(mem_file,"%h\n",u_top.u_shared_mem.u_mem.r_mem[i]);
    end
    $fclose(mem_file);
    $finish ; 
end
endmodule



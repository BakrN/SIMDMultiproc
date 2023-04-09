`include "top.sv"
`timescale 1ns/1ps
`ifndef CMD_SIZE 
`define CMD_SIZE 5
`endif
module tb_top() ;
parameter T = 10 ;
// top Inputs
logic i_clk;
logic i_rstn;
cmd_t queue_cmd;
logic queue_empty;

// top Outputs
logic   issuer_rd_queue;
top  u_top (
    .i_clk                    ( i_clk                     ),
    .i_rstn                   ( i_rstn                    ),
    .queue_cmd                ( queue_cmd           ),
    .queue_empty              ( queue_empty),
    .issuer_rd_queue          ( issuer_rd_queue   ),
);

initial begin
    forever begin
        i_clk = 0 ;
        #(T/2) ;
        i_clk = 1 ;
        #(T/2) ;
    end
end
reg [31:0] dep_mem [`MEM_SIZE-1:0];   // if issuer needs a new cmd ? 
cmd_t cmd_queue [`CMD_SIZE-1:0] ; 

// In this test I will just stall if there is a dependency 
initial begin
    // Load initial mem 
    $readmemh("sim/start_mem.txt",u_top.u_shared_mem.u_mem.mem);
    $readmemh("sim/start_mem.txt",cmd_queue);
    // reset 
    i_rstn = 0 ; 
    #T ;
    i_rstn = 1 ;  
    #T ;
    queue_empty = 0 ;  
    
    for (int i = 0 ; i < `CMD_SIZE; i++) begin
        queue_cmd = cmd_queue[i]; 
        while(!issuer_rd_queue) begin 
            #T ; 
        end
    end
    queue_empty  = 1; 

end
endmodule



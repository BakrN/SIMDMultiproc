`include "top.sv"
`ifndef TEST_SIZE
`define TEST_SIZE 5 
`endif
module tb_top() ; 
parameter T = 10 ; 
// top Inputs
logic i_clk;
logic i_rstn;
cmd_t queue_cmd;
logic queue_ack;

// top Outputs
logic   issuer_rd_queue;
logic   issuer_wr_queue;
cmd_t   issuer_cmd;
top  u_top (
    .i_clk                    ( i_clk                     ),
    .i_rstn                   ( i_rstn                    ),
    .queue_cmd                ( queue_cmd           ),
    .queue_ack                ( queue_ack           ),
    .issuer_rd_queue          ( issuer_rd_queue   ),
    .issuer_wr_queue          ( issuer_wr_queue   ),
    .issuer_cmd               ( issuer_cmd        )
);

initial begin
    forever begin
        i_clk = 0 ; 
        #(T/2) ;
        i_clk = 1 ; 
        #(T/2) ;
    end 
end
reg [31:0] dep_mem [`MEM_SIZE-1:0]; ;  // if issuer needs a new cmd ? 
// Initial values
initial begin  
    // Load initial mem 
    $readmemh("sim/start_mem.txt",u_top.u_shared_mem.u_mem.mem);  
    i_rstn = 1; 
    //new_cmd = 1; 
end
// In this test I will just stall if there is a dependency 
initial begin 
    for (int i = 0 ; i < `TEST_SIZE; i++) begin 
        //i_cmd = %f

    end

end
endmodule 



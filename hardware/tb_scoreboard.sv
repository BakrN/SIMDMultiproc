`include "scoreboard.sv"

module tb_scoreboard; 
localparam T = 10;
// scoreboard Inputs
logic   i_clk;
logic   i_rstn;
entry_t i_entry;
logic i_write;
logic i_flush;
logic i_read;

scoreboard  u_scoreboard (
    .i_clk                      ( i_clk                       ),
    .i_rstn                     ( i_rstn                      ),
    .i_entry                    ( i_entry             ), 
    .i_write                    ( i_write                     ),
    .i_flush                    ( i_flush                     ),
    .i_read                     ( i_read                      ),
    .o_id                       (  o_id   ),
    .o_exists                   ( o_exists                    )
); 
// starting initializations
logic [ID_WIDTH-1:0] o_id;
logic o_exists; 
initial begin
    forever begin
    i_clk = 0;
    #(T/2) ; 
    i_clk = 1;
    #(T/2) ; 
    end
    i_rstn = 1;
    i_entry.cmd_id = 2 ; 
    i_entry.proc_id = 1;  
    i_write = 0; 
    i_flush = 0;
    i_read = 0; 
end
    
// Testing the scoreboard
initial begin 
    #T ; 
    // Test write 
    
    // Test Read 

    // Test Flush

end

endmodule
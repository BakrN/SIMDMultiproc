`include "defines.sv"
`include "issuer.sv"
`define dump_scoreboard(inst) \
  begin \ 
  entry_t t;\
  $display("dumping scoreboard contents");      \
  $display("Key   Value   Valid") ; \
  for (integer i = 0 ; i < `PROC_COUNT; i ++) begin \
  t= inst.map[i]; \
  $display("%d      %d       %b", t.cmd_id, t.proc_id, inst.valid_table[i]) ;  \ 
  end \
  end
`define assert_equals(signal1, signal2, message) \
  if (signal1 !== signal2) begin \
    $error("Assertion failed: signal1:%d , signal2:%d ,%s", signal1, signal2, message); \
  end else begin \
    $display("signal1: %d and signal2: %d were equal", signal1, signal2); \
  end

module issuer_tb; 
parameter T = 10 ; 
// issuer Inputs
logic i_clk;
logic i_rstn;
logic i_ack_queue;
logic [`PROC_COUNT-1:0]  i_busy_proc;
logic [`PROC_COUNT-1:0]  i_finish_proc;
logic [`PROC_COUNT-1:0]  i_ack_proc;
logic [`PROC_COUNT-1:0]  o_en_proc;
logic [`PROC_COUNT-1:0]  o_ack_proc;
cmd_t i_cmd;

// issuer Outputs
instr_t o_instr;
logic o_rd_queue;
logic o_wr_queue;
cmd_t o_cmd;

issuer  u_issuer (
    .i_clk                   (     i_clk          ),
    .i_rstn                  (     i_rstn         ),
    .i_ack_queue             (     i_ack_queue    ), // need extra line for proc ack . Or maybe use the finished bus lines ? 
    .i_ack_proc             (     i_ack_proc   ), 
    .i_busy_proc             (     i_busy_proc    ),
    .i_finish_proc           (     i_finish_proc  ),
    .o_en_proc               (     o_en_proc      ),
    .o_ack_proc              (     o_ack_proc     ),
    .i_cmd                   (     i_cmd          ),
    .o_instr                 (     o_instr        ),
    .o_rd_queue              (     o_rd_queue     ),
    .o_wr_queue              (     o_wr_queue     ),
    .o_cmd                   (     o_cmd          )
);
// clock isntantiation 
initial begin 
    forever begin 
        i_clk = 0 ; 
        #(T/2) ; 
        i_clk = 1 ; 
        #(T/2) ; 
    end 
end
initial begin 
    $dumpfile("sim/issuer.vcd");
    $dumpvars(0, u_issuer);
end
cmd_t new_cmd; 
initial begin 
    i_cmd = 0 ; 
    i_cmd.id =  1; 
    i_cmd.dep =  0;   
    new_cmd.id = 2 ; 
    new_cmd.dep = 1 ; 
    i_ack_queue = 0 ; 
    i_ack_proc = 0; 
    i_finish_proc = 0 ; 
end 

initial begin 
    /* ------------------------------- FSM Testing ------------------------------ */
    i_rstn = 0  ; 
    #T ; 
    i_rstn = 1  ; 
    #(3*T) ;  
    `assert_equals (u_issuer.state, u_issuer.IDLE , "Issuser should be idling while waiting for proc to free up")
    i_busy_proc = 4'b1011; 
    #T;  
    `assert_equals (u_issuer.state, u_issuer.CMD_GET, "Issuer should now be fetching a command")
    `assert_equals (u_issuer.o_rd_queue, 1 , "Reading from queue")
    #T; 
    i_cmd = new_cmd; 
    `assert_equals (u_issuer.state, u_issuer.CMD_CHECK, "Checking with scoreboard")
    #(3*T); 
    `assert_equals (u_issuer.state, u_issuer.SIMD_SELECT, "Picking free SIMD") 
    `assert_equals (u_issuer.selected_proc, 2 , "only free proc")    
    #(3*T) ;
    `dump_scoreboard(u_issuer.u_scoreboard)
    i_busy_proc = 4'hF; 
    `assert_equals (u_issuer.state, u_issuer.SIMD_LD1, "LoadingSIMD1") #T; 
    `assert_equals (u_issuer.state, u_issuer.WAIT_ACK, "Waiting for proc confirmation of recieved data") #T ; 
    `assert_equals (u_issuer.state, u_issuer.WAIT_ACK, "Waiting for proc confirmation of recieved data") 
    i_ack_proc = 4'hF;  
    #T; 
    `assert_equals (u_issuer.state, u_issuer.SIMD_LD2, "Loading SIMD2") #T; 
    `assert_equals (u_issuer.state, u_issuer.WAIT_ACK, "Waiting for proc confirmation of recieved data") 
    #T; 
    `assert_equals (u_issuer.state, u_issuer.SIMD_INFO, "Setting INFO") #T; 
    `assert_equals (u_issuer.state, u_issuer.WAIT_ACK, "Waiting for proc confirmation of recieved data") 
    #(5*T);  
    `assert_equals (u_issuer.state, u_issuer.IDLE, "Waiting for busy proc to finish")
    // Try inserting new val that is dependent 
    i_busy_proc = 4'b1110; 
    #T; 
    `assert_equals (u_issuer.state, u_issuer.CMD_GET, "Getting cmd") 
    #T ;
    `assert_equals (u_issuer.state, u_issuer.CMD_CHECK, "Checking for depended cmds") 
    #(3*T);  
    `assert_equals (u_issuer.state, u_issuer.CMD_WRITEBACK, "Writing back dep cmd") 
    #(3*T) ; // waiting for ack
    `assert_equals (u_issuer.state, u_issuer.WAIT_ACK, "Waiting for queue ack") 
    i_ack_queue =1 ;
    i_finish_proc  = 4'b0100;  // Finished 1st cmd
    # T; 
    `assert_equals (u_issuer.state, u_issuer.IDLE, "Issuer should now be idling checkinng for finished cmds")
    # T; 
    `assert_equals (u_issuer.state, u_issuer.PROC_FINISH, "Finished Processor state")
    `assert_equals (u_issuer.finish_bit_pos, 2, "Making sure finish signal is triggered correctly")
    
    while(u_issuer.state== u_issuer.PROC_FINISH) begin
      # T ; 
    end
    `assert_equals (u_issuer.state , u_issuer.SEND_ACK , "Sending finish ack to prco")
    i_finish_proc = 0 ; 
    #T; 
    `assert_equals (u_issuer.state , u_issuer.IDLE, "Issuer should now be idling checkinng for finished cmds")
    // now make sure 2nd command is assigned to  proc 
    #T;  
    `assert_equals (u_issuer.state, u_issuer.CMD_GET, "Issuer should now be fetching a command")
    `assert_equals (u_issuer.o_rd_queue, 1 , "Reading from queue")
    #T; 
    `assert_equals (u_issuer.state, u_issuer.CMD_CHECK, "Checking with scoreboard")
    #(3*T); 
    `assert_equals (u_issuer.state, u_issuer.SIMD_SELECT, "Picking free SIMD")  
    $finish; 
end
endmodule
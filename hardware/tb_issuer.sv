`include "defines.sv"

module issuer_tb; 
parameter T = 10 ; 
// Need to test command sources more thoroughly whether fromm queue or internal fifo

// issuer Inputs
logic i_clk;
logic i_rstn;
logic i_empty_queue;
logic [`PROC_COUNT-1:0]  i_busy_proc;
logic [`PROC_COUNT-1:0]  i_finish_proc;
logic [`PROC_COUNT-1:0]  i_ack_proc;
cmd_t i_cmd;

// issuer Outputs
logic [`PROC_COUNT-1:0] o_en_proc;
logic [`PROC_COUNT-1:0] o_ack_proc;
instr_t o_instr;
logic o_rd_queue;

issuer  u_issuer (
    .i_clk          ( i_clk           ),
    .i_rstn         ( i_rstn          ),
    .i_empty_queue  ( i_empty_queue   ),
    .i_busy_proc    ( i_busy_proc     ),   
    .i_finish_proc  ( i_finish_proc   ), 
    .i_ack_proc     ( i_ack_proc      ),
    .i_cmd          (i_cmd            ),
    .o_en_proc      ( o_en_proc       ), 
    .o_ack_proc     (o_ack_proc       ),   
     .o_instr       ( o_instr         ),
     .o_rd_queue    ( o_rd_queue      )
     );


cmd_t nxt_cmd ; 
// clock isntantiation  
initial begin 
   
end
initial begin 
end 
initial begin 
    $dumpfile("sim/tb_issuer.vcd");
    $dumpvars(0, u_issuer);
end
cmd_t new_cmd; 
initial begin 
   forever begin 
        i_clk = 0 ; 
        #(T/2) ; 
        i_clk = 1 ; 
        #(T/2) ; 
    end 
    
end 

initial begin 
    /* ------------------------------- FSM Testing ------------------------------ */
    i_rstn = 0  ; 
    #T ; 
    i_rstn = 1  ; 
    #(30*T) ;  
    i_empty_queue =  0 ;  
    // INITIAL STATE 
    i_cmd = 0 ; 
    i_cmd.id =  1; 
    i_cmd.dep =  0;   
    new_cmd.id = 2 ; 
    new_cmd.dep = 1 ; 
    i_ack_proc = 0; 
    i_finish_proc = 0 ; 
    i_empty_queue = 0 ; 
    /// 
    `assert_equals (u_issuer.state, u_issuer.IDLE , "Issuser should be idling while waiting for proc to free up")
    i_busy_proc = 4'b1011; 
    #T;  
    `assert_equals (u_issuer.state, u_issuer.CMD_GET, "Issuer should now be fetching a command")
    `assert_equals (u_issuer.o_rd_queue, 1 , "Reading from queue")
    #T; 
    i_cmd = new_cmd; 
    `assert_equals (u_issuer.state, u_issuer.CMD_CHECK, "Checking CAM ")
    #(2*T); 
    `assert_equals (u_issuer.state, u_issuer.CAM_WRITE, "Writing cmd to CAM")  
    #T; while (u_issuer.cam_write_busy) #T;
    #T;  
    `assert_equals (u_issuer.state, u_issuer.SIMD_SELECT, "Picking free SIMD") 
    `assert_equals (u_issuer.selected_proc, 2 , "only free proc")     
    #T;
    i_busy_proc = 4'hF; 
    `assert_equals (u_issuer.state, u_issuer.SIMD_LD1, "LoadingSIMD1") #T; 
    `assert_equals (u_issuer.state, u_issuer.WAIT_ACK, "Waiting for proc confirmation of recieved data") #T ; 
    i_ack_proc = 4'hF;  
    #T; 
    `assert_equals (u_issuer.state, u_issuer.SIMD_LD2, "Loading SIMD2") #T; 
    `assert_equals (u_issuer.state, u_issuer.WAIT_ACK, "Waiting for proc confirmation of recieved data") 
    #T; 
    `assert_equals (u_issuer.state, u_issuer.SIMD_INFO, "Setting INFO") #T; 
    `assert_equals (u_issuer.state, u_issuer.WAIT_ACK, "Waiting for proc confirmation of recieved data") 
    #T ; 
    `assert_equals (u_issuer.state, u_issuer.SIMD_STORE, "Saving writeback address") #T; 
    `assert_equals (u_issuer.state, u_issuer.WAIT_ACK, "Waiting for proc confirmation of recieved data") 
    #(5*T);  
    `assert_equals (u_issuer.state, u_issuer.IDLE, "Waiting for busy proc to finish")
    // Try inserting new val that is dependent 
    i_busy_proc = 4'b1110; 
    #T; 
    `assert_equals (u_issuer.state, u_issuer.CMD_GET, "Getting cmd") 
    #T ;
    `assert_equals (u_issuer.state, u_issuer.CMD_CHECK, "Checking for depended cmds") 
    #(2*T);  
    `assert_equals (u_issuer.state, u_issuer.CAM_WRITE, "Writing cmd to CAM")  
    #T ; while (u_issuer.cam_write_busy) #T;  
    #T; 
    `assert_equals (u_issuer.state, u_issuer.CMD_WRITEBACK, "Writing back dep cmd") 
    i_finish_proc  = 4'b0100;  // Finished 1st cmd
    # T; 
    `assert_equals (u_issuer.state, u_issuer.IDLE, "Issuer should now be idling checkinng for finished cmds")
    # T; 
    `assert_equals (u_issuer.state, u_issuer.PROC_FINISH, "Finished Processor state")
    `assert_equals (u_issuer.finish_bit_pos, 2, "Making sure finish signal is triggered correctly")
    `assert_equals (u_issuer.cmd_source , 1 ,  "Command source should be the FIFO ")
    while(u_issuer.state== u_issuer.PROC_FINISH) begin // Waiting for cam to delete it 
      # T ;  
    end
    `assert_equals (u_issuer.state , u_issuer.SEND_ACK , "Sending finish ack to prco")
    i_finish_proc = 0 ; 
    #T; 
    `assert_equals (u_issuer.state , u_issuer.IDLE, "Issuer should now be idling checkinng for finished cmds")
    // now make sure 2nd command is assigned to  proc 
    #T;  
    `assert_equals (u_issuer.state, u_issuer.CMD_GET, "Issuer should now be checking with the dep_fifos") 
    `assert_equals (u_issuer.dep_read, 1 , "Reading from dependency queue")
    #T; 
    `assert_equals (u_issuer.state, u_issuer.CMD_CHECK, "Checking with cam")
    #(2*T); 
    `assert_equals (u_issuer.state, u_issuer.CAM_WRITE, "Overwriting cmd in CAM")  
    #T;  while (u_issuer.cam_write_busy) #T;  
    #T;  
    `assert_equals (u_issuer.state, u_issuer.SIMD_SELECT, "Picking free SIMD")  
    $finish; 
end
endmodule
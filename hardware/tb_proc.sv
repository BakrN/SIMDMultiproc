`include "proc.sv"
`ifndef TEST_COUNT
`define TEST_COUNT 100 
`endif 
`define assert_equals(signal1, signal2, message) \
  if (signal1 !== signal2) begin \
    $error("Assertion failed: signal1:%d , signal2:%d ,%s", signal1, signal2, message); \
  end else begin \
    $display("signal1: %d and signal2: %d were equal", signal1, signal2); \
  end

  

module proc_tb; 
    parameter T = 10 ; 
    // proc Inputs
    instr_t i_instr;
    logic i_clk;
    logic i_rstn;
    logic i_en;
    logic i_grant_rd;
    logic i_grant_wr;
    logic i_valid;
    logic [127:0] i_data;

    // proc Outputs
    logic o_finish;
    logic o_req_rd;
    logic o_req_wr;
    logic o_busy;
    logic o_ack;
    addr_t o_addr;
    logic[1:0] o_wr_size;
    logic [127:0]  o_data;
    proc  u_proc (
        .i_instr                 (       i_instr        ),
        .i_clk                   (       i_clk          ),
        .i_rstn                  (       i_rstn         ),
        .i_en                    (       i_en           ),
        .i_grant_rd              (       i_grant_rd     ),
        .i_grant_wr              (       i_grant_wr     ),
        .i_valid                 (       i_valid        ),
        .i_data                  (       i_data         ),
        .o_finish                (       o_finish       ),
        .o_req_rd                (       o_req_rd       ),
        .o_req_wr                (       o_req_wr       ),
        .o_busy                  (       o_busy         ),
        .o_ack                   (       o_ack          ),
        .o_addr                  (       o_addr         ),
        .o_wr_size               (       o_wr_size      ),
        .o_data                  (       o_data         )
    );
    // clock instantiation 
    initial begin 
      forever begin
        i_clk = 0 ; 
        #T ; 
        i_clk = 1 ; 
        #T ;  
      end
    end 
    // default states setup 
    initial begin  
      i_en = 0 ; 
      i_grant_rd = 0 ; 
      i_grant_wr = 0 ; 
      i_valid = 0 ; 
      i_instr = 0 ; 
      i_data = 0 ; 
    end

    instr_info_t temp_instr_info ;
    initial begin  
      /* ------------------------------- FSM Testing ------------------------------ */
      // rest and idle
      i_rstn = 0 ;
      #T ; 
      i_rstn = 1; 
      #(3*T) ; 
      `assert_equals(u_proc.state , u_proc.IDLE , "PROCESSOR IS NOT IDLE WHEN IT NEEDS TO BE" ) 
      #T ; 
      // test enable
      i_en = 1 ; 
      #T ; 
      `assert_equals(u_proc.state , u_proc.LD1 , "Processor should be waiting for addr 0 " ) // loading addr of 1st 
      #T; 
      // should stay on load 1 since i_valid and instr_opcode wasn't correct 
      i_valid =  1; 
      #T ; 
      i_instr.opcode = INSTR_LD ; 
      i_instr.payload = 1 ; 
      #T ; 
      i_instr.payload = 2 ; 
      // now should move on to load 2 
      `assert_equals(u_proc.state , u_proc.LD2 , "Processor should be waiting for addr 1 " ) 
      #T ; 
      // check value of registers and state 
      `assert_equals(u_proc.addr_0, 1, "Address 0 should've been set according to payload" ) 
      `assert_equals(u_proc.addr_1, 2, "Address 1 should've been set according to payload" )  
      `assert_equals(u_proc.state , u_proc.SET_INFO, "PRocessor should waiting for instruction info" ) 
      i_instr.opcode = INSTR_INFO; 
      temp_instr_info.count = 5 ; 
      temp_instr_info.op = 2 ;  // sub
      temp_instr_info.overwrite = 0 ;
      i_instr.payload = temp_instr_info ; 
      #T ; 
      
      `assert_equals(u_proc.state , u_proc.FETCH1, "Processor should be trying to fetch 1st values to do instr" )  
      `assert_equals(u_proc.instr_info, temp_instr_info, "Instruction info don't match" )  
      `assert_equals(o_req_rd , 1 ,"Should be requesting read here but am not")  
      `assert_equals(o_req_wr , 0 , "shouldn't be requesting write here")
      i_data = 128'd2398439 ;  
      i_grant_rd =1 ;  // granted read   
      #T ; 
      i_data = -128'd123989;  
      `assert_equals(u_proc.state , u_proc.FETCH2, "Processor should be trying to fetch 2nd values to do instr" )  
      #T ; 
      // should be requesting write grant 

      /* ------------------------ Logic Arithmetic Testing ------------------------ */
      
    end
endmodule
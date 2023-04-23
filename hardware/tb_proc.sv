`include "proc.sv"
`ifndef TEST_COUNT
`define TEST_COUNT 1000
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
    logic [4:0][31:0] i_data;

    // proc Outputs
    logic o_finish;
    logic o_req_rd;
    logic o_req_wr;
    logic o_busy;
    logic o_ack;
    addr_t o_addr;
    logic[2:0] o_wr_size;
    logic [4:0][31:0] o_data;
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
    integer f_input, f_val_add, f_val_sub , f_val_mul , f_test_add, f_test_sub, f_test_mul; 
    // clock instantiation 
    initial begin 
      forever begin
        i_clk = 0 ; 
        #(T/2) ; 
        i_clk = 1 ; 
        #(T/2) ;  
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
      // * VALIDATED
      $display("VALIDATING FSM") ; 
      // rest and idle
      i_rstn = 0 ;
      #T ; 
      i_rstn = 1; 
      #(3*T) ; 
      `assert_equals(u_proc.state , u_proc.IDLE , "PROCESSOR IS NOT IDLE WHEN IT NEEDS TO BE" ) 
      #T ; 
      // test enable
      i_en = 1 ; 
      i_instr.opcode = INSTR_INFO; // to halt the fsm 
      #T ; 
      `assert_equals(u_proc.state , u_proc.LD1 , "Processor should be waiting for addr 0 " ) // loading addr of 1st 
      #T; 
      // should stay on load 1 since i_valid and instr_opcode wasn't correct 
      i_valid =  1; 
      
      #T ; 
      `assert_equals(u_proc.state , u_proc.LD1 , "Processor should be waiting for addr 0 " ) // loading addr of 1st  
      i_instr.payload = 1 ; 
      i_instr.opcode = INSTR_LD ; 
      
      #T ; // 1 cycle when proc check again and then 1 more to be on ld 2
      i_instr.payload = 200 ; 
      // now should move on to load 2 
      `assert_equals(u_proc.state , u_proc.LD2 , "Processor should be waiting for addr 1 " ) 
      #T ; 
      // check value of registers and state 
      `assert_equals(u_proc.addr_0, 1, "Address 0 should've been set according to payload" ) 
      `assert_equals(u_proc.addr_1, 200, "Address 1 should've been set according to payload" )  
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
      i_data = 2398439 ;  
      i_grant_rd =1 ;  // granted read   
      #T ; // two cycles for waiting on grant 
      i_data = -123989 ;  
      `assert_equals(u_proc.state , u_proc.FETCH2, "Processor should be trying to fetch 2nd values to do instr" )  
      #T ; 
      `assert_equals(u_proc.state , u_proc.WRITE, "Processor should have been in WRITE state" )  
      // asert that data in reg is equal 
      `assert_equals(u_proc.reg0,2398439  , "value in reg0 is incorrect" )  
      `assert_equals(u_proc.reg1, -123989 , "value in reg1 is incorrect" )  
      `assert_equals(o_req_wr , 1 , "Should be requesting write access") 
      `assert_equals(o_wr_size, 4 , "Should be writing back full mem block ") 
      i_grant_wr = 1 ;
      # T ; 
      `assert_equals(u_proc.instr_info.count , 1, "assert that count has been decremented correctly ") 
      `assert_equals(u_proc.state , u_proc.FETCH1, "Should loop back" )   
      `assert_equals(u_proc.addr_0 , 129 , "Address 0 wasn't incremented correctly") 
      `assert_equals(u_proc.addr_1 , 328 , "Address 1 wasn't incremented correctly")  
      #T; 
      `assert_equals(u_proc.state , u_proc.FETCH2, "state" )   
      #T; 
      `assert_equals(u_proc.state , u_proc.WRITE, "state" )    
      `assert_equals(o_wr_size, 1 , "Should be writing back only 1 block")  
      i_instr.opcode = INSTR_INFO; // for logic arithmetic part
      #T; 
      
      `assert_equals(u_proc.state , u_proc.FINISHED, "FINISHED" )    
      i_en = 0 ;
      #T; 

      $display("VALIDATING ARITHMETIC UNIT") ; 
      /* ------------------------ Logic Arithmetic Testing ------------------------ */ 
      
      f_test_add = $fopen("test/test_add.txt","w");
      f_test_sub = $fopen("test/test_sub.txt","w"); 
      f_test_mul = $fopen("test/test_mul.txt","w");
      // setup 
      temp_instr_info.count = 4;  
      i_en = 1 ; 
      i_valid = 1; 
      i_grant_rd =1 ; 
      i_grant_wr =1 ; 
      for (integer op = 0 ; op < 3; op++)  begin 
        f_input    = $fopen("test/inputs.txt","r");
        for (integer i = 0 ; i < `TEST_COUNT ; i++) begin 
          i_instr.opcode = INSTR_LD ; 
          #(2*T) ; 
          // `assert_equals(u_proc.state, u_proc.LD2 , "Should be on ld2")  
          #T; 
          i_instr.opcode = INSTR_INFO ; 
          i_instr.payload.count = 4;  
          i_instr.payload.op    = op;  // add 
          i_instr.payload.overwrite    = 0;  
          //`assert_equals(u_proc.state, u_proc.SET_INFO, "SET_INFO")  
          #T ; 
          //`assert_equals(u_proc.state, u_proc.FETCH1, "should be on fetch1")  
          $fscanf(f_input,"%h,%h,%h,%h\n",i_data[3], i_data[2] , i_data[1], i_data[0]);
          #T; 
          //`assert_equals(u_proc.state, u_proc.FETCH2, "should be on fetch2")  
          $fscanf(f_input,"%h,%h,%h,%h\n",i_data[3], i_data[2] , i_data[1], i_data[0]);
          #T;  
          //`assert_equals(u_proc.state, u_proc.WRITE, "Should be on write")   
          if (op == 0 ) begin 
            $fdisplay(f_test_add,"%h,%h,%h,%h",o_data[3], o_data[2],o_data[1], o_data[0]);
          end else if (op ==1) begin 
            $fdisplay(f_test_sub,"%h,%h,%h,%h",o_data[3], o_data[2],o_data[1], o_data[0]);
          end else begin 
            $fdisplay(f_test_mul,"%h,%h,%h,%h",o_data[3], o_data[2],o_data[1], o_data[0]);
          end
          #T ; 
          //`assert_equals(u_proc.state, u_proc.FINISHED, "Should be on write")   
          #T; 
          // wait until it turns back to idle
        end
      end
      $finish ;
    end
endmodule

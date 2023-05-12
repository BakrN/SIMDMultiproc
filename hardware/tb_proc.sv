`include "proc.sv"
`define TEST_COUNT 1000  
`define MAT_SIZE 16
`define assert_equals(signal1, signal2, message) \
  if (signal1 !== signal2) begin \
    $error("Assertion failed: signal1:%d , signal2:%d ,%s", signal1, signal2, message); \
  end else begin \
    $display("signal1: %d and signal2: %d were equal", signal1, signal2); \
  end


module proc_tb; 
    parameter T = 10 ; 
    parameter SIMD_WIDTH = 4 ;
    // proc Inputs
    cmd_info_t i_cmd;
    logic i_clk;
    logic i_rstn;
    logic i_en;
    logic i_grant_rd;
    logic i_grant_wr;
    logic [SIMD_WIDTH-1:0][31:0] i_data;

    // proc Outputs
    logic o_finish;
    logic o_req_rd;
    logic o_req_wr;
    logic o_busy;
    addr_t o_addr;
    logic[2:0] o_wr_size;
    logic [SIMD_WIDTH-1:0][31:0] o_data;
    proc#(.SIMD_WIDTH(SIMD_WIDTH))  u_proc (
        .i_cmd (       i_cmd),
        .i_clk                   (       i_clk          ),
        .i_rstn                  (       i_rstn         ),
        .i_en                    (       i_en           ),
        .i_grant_rd              (       i_grant_rd     ),
        .i_grant_wr              (       i_grant_wr     ),
        .i_data                  (       i_data         ),
        .o_finish                (       o_finish       ),
        .o_req_rd                (       o_req_rd       ),
        .o_req_wr                (       o_req_wr       ),
        .o_busy                  (       o_busy         ),
        .o_addr                  (       o_addr         ),
        .o_wr_size               (       o_wr_size      ),
        .o_data                  (       o_data         )
    );
    integer f_input, f_test_add, f_test_sub, f_test_mul , f_test_mul_2x , f_test_mul_3x ; 
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
      i_cmd = 0 ; 
      i_data = 0 ; 
    end

    cmd_info_t temp_instr_info ;
    logic [31:0] mat_data [31]; 
    logic [31:0] vec_data [16]; 
    initial begin  
      /* ------------------------------- FSM Testing ------------------------------ */
      $display("VALIDATING FSM") ; 
      // rest and idle
      i_rstn = 0 ;
      #T ; 
      i_rstn = 1; 
      #(3*T) ; 
      `assert_equals(u_proc.state , u_proc.IDLE , "PROCESSOR IS NOT IDLE WHEN IT NEEDS TO BE" ) 
      #T ;  
      /* ------------------------------- SUB/ADD FSM Testing ------------------------------ */
      // test enable
      i_en = 1 ; 
      i_cmd.op = 1 ; //add 
      i_cmd.addr_0 = 1 ; 
      i_cmd.addr_1 = 200 ; 
      i_cmd.count = 6 ;
      i_cmd.wr_addr = 100 ;
      #T ; 
      `assert_equals(u_proc.state , u_proc.LD_CMD, "Processor should be loading " ) // loading addr of 1st 
      #T; 
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
      `assert_equals(u_proc.reg0,2398439  , "value in reg0 is incorrect" )   // error here
      `assert_equals(u_proc.reg1, -123989 , "value in reg1 is incorrect" )  
      `assert_equals(o_req_wr , 1 , "Should be requesting write access") 
      `assert_equals(o_wr_size, 4 , "Should be writing back full mem block ") 
      i_grant_wr = 1 ;
      # T ; 
      `assert_equals(u_proc.task_size, 2, "assert that count has been decremented correctly ") 
      `assert_equals(u_proc.state , u_proc.FETCH1, "Should loop back" )   
      `assert_equals(u_proc.addr_0 , 5, "Address 0 wasn't incremented correctly") 
      `assert_equals(u_proc.addr_1 , 204 , "Address 1 wasn't incremented correctly")  
      #T; 
      `assert_equals(u_proc.state , u_proc.FETCH2, "state" )   
      #T; 
      `assert_equals(u_proc.state , u_proc.WRITE, "state" )    
      `assert_equals(o_wr_size, 2 , "Should be writing back only 2 block")  
      #T; 
      
      `assert_equals(u_proc.state , u_proc.FINISHED, "FINISHED" )    
      i_en = 1 ; 
      #T;  
      i_en = 0 ; 
      `assert_equals(u_proc.state,u_proc.IDLE, "IDLE")

      /* ------------------------------- SUB/ADD FSM Testing END ------------------------------ */
      /* ------------------------------- MATMUL FSM Testing ------------------------------ */

      /* ------------------------------- MATMUL FSM Testing END ------------------------------ */
      i_cmd.op    = 2 ; // matmul 
      i_cmd.count = 16 ; // should be finshed in 4 steps 
      i_cmd.addr_0 = 100 ;
      i_cmd.addr_1 = 300 ;  
      i_cmd.wr_addr = 250 ; 
      #T ;   
      `assert_equals(u_proc.state,u_proc.IDLE, "IDLE")

      i_en = 1 ;

      #T; 
      `assert_equals(u_proc.state , u_proc.LD_CMD, "Processor should be loading " ) // loading addr of 1st 
      #T ; 
      `assert_equals(u_proc.state , u_proc.FETCH1, "SHould be Fetch1" ) // loading addr of 1st 
      #T ; 
      `assert_equals(u_proc.state , u_proc.PRE_FETCH, "SHould be PRE_FETCH since 16>SIMD_WIDTh" ) // loading addr of 1st 
      #T ; 
      `assert_equals(u_proc.state , u_proc.FETCH2, "SHould be on FETCH2" ) // loading addr of 1st 
      #T ; 
       for (int row = 0 ; row < 4; row++) begin
        for (int col = 0 ; col < 4; col++) begin 
        `assert_equals(u_proc.current_row, SIMD_WIDTH*row, "current row is incorrect" )
        `assert_equals(u_proc.current_col, SIMD_WIDTH*col, "current col is incorrect" )
         for (int i = 0 ;  i <4 ; i++) begin // calculation for 1 simd cycle
        `assert_equals(u_proc.state , u_proc.MATMUL, "SHould be on MATMUL" ) // loading addr of 1st 
        `assert_equals(u_proc.mac_ops_done, i, "mac ops done" ) 
        for (int index = 0 ; index < 4 ; index++) begin
            if ((SIMD_WIDTH-index-1) + i>= SIMD_WIDTH) begin 
                `assert_equals(u_proc.arr_a[index],u_proc.matrix_prefetch_reg[(SIMD_WIDTH-(i-index-1))*32-1-:32] , "Not correct matrix_prefetch index" ) 
            end else begin  
                `assert_equals(u_proc.arr_a[index],u_proc.reg0[(index-i)*32+:32] , "arr_a") 
            end
            `assert_equals(u_proc.arr_b[index],u_proc.reg1[(i)*32+:32] , "arr_b" ) 
        end
        #T ;
        while (u_proc.arr_valid != 1) begin 
          #T ; 
        end
        `assert_equals(u_proc.arr_valid,1 , "arr_valid" )
        #T;  
        end
        if (col!=3) begin
        `assert_equals(u_proc.state ,u_proc.NEXT_COL, "Should be going to next col" )
        #T;  
        `assert_equals(u_proc.addr_0, i_cmd.addr_0+ (SIMD_WIDTH*(col+2)), "addr_0" ) 
        `assert_equals(u_proc.addr_1, i_cmd.addr_1+ (SIMD_WIDTH*(col+1)), "addr_1" )
        `assert_equals(u_proc.state ,u_proc.SHIFT_REG, "Shift Reg" )
        #T ; 
        `assert_equals(u_proc.state ,u_proc.PRE_FETCH, "PRE_FETCH" ) 
        #T ;
        `assert_equals(u_proc.state ,u_proc.FETCH2, "Fetching vec failed" ) 
        #T ; 
        end 
        //$finish; 
        // done a mac oepration
        end  
        `assert_equals(u_proc.state ,u_proc.NEXT_ROW, "Should be going to next row" )
        #T;
        `assert_equals(u_proc.addr_1 , i_cmd.addr_1, "col should reset" )  
        `assert_equals(u_proc.addr_0 , i_cmd.addr_0+SIMD_WIDTH*(row+1), "row should be refetched" )  
        `assert_equals(u_proc.state ,u_proc.WRITE, "Writing back result" ) 
        #T;  
        if (row!=3) begin 
        `assert_equals(u_proc.task_size,16-SIMD_WIDTH*(row+1), "task_size" )
        `assert_equals(u_proc.state ,u_proc.SHIFT_REG, "SHIFT_REG" )
        #T; 
        `assert_equals(u_proc.state ,u_proc.PRE_FETCH, "PRE_FETCH" )
        #T; 
        `assert_equals(u_proc.state ,u_proc.FETCH2, "FETCH2" )
        #T;   
        end else begin  
        i_en = 0 ; 
        `assert_equals(u_proc.state ,u_proc.FINISHED, "FINISHED" )
        end
    end
      #T ;
      $display("VALIDATING Multiple  operations") ; 
      /* ------------------------ Logic Arithmetic Testing ------------------------ */ 
      /* ------------------------ Logic Arithmetic Testing ------------------------ */ 

      /* ------------------------       ADD/SUB TESTING    ------------------------ */ 
      f_test_add = $fopen("py/tests/proc/test_add.txt","w");
      f_test_sub = $fopen("py/tests/proc/test_sub.txt","w"); 
      // setup 
      i_en = 1 ; 
      i_grant_rd =1 ; 
      i_grant_wr =1 ; 
      #(2*T) ;
      for (integer op = 0 ; op < 2; op++)  begin 
        f_input    = $fopen("py/tests/proc/inputs.txt","r");
        for (integer i = 0 ; i < `TEST_COUNT ; i++) begin 
          i_cmd.op = op; 
          i_cmd.count = SIMD_WIDTH;  
          #T; 
          //`assert_equals(u_proc.state, u_proc.FETCH1, "should be on fetch1")  
           $fscanf(f_input,"%h,%h,%h,%h\n",i_data[3],i_data[2],i_data[1] ,i_data[0]);

          #T; 
           //`assert_equals(u_proc.state, u_proc.FETCH2, "should be on fetch2")  
           //`assert_equals(u_proc.reg0, i_data, "reg0")
           //$display("%h,%h,%h,%h\n",u_proc.reg0[127-:32],u_proc.reg0[95-:32],u_proc.reg0[63-:32] ,u_proc.reg0[31-:32]);
           $fscanf(f_input,"%h,%h,%h,%h\n",i_data[3],i_data[2],i_data[1] ,i_data[0]);
          #T;  
           //$display("%h,%h,%h,%h\n",u_proc.reg1[127-:32],u_proc.reg1[95-:32],u_proc.reg1[63-:32] ,u_proc.reg1[31-:32]);
          // `assert_equals(u_proc.reg1, i_data, "reg1")
          //`assert_equals(u_proc.state, u_proc.WRITE, "Should be on write")   


           #T ;
          if (op == 0 ) begin 
                for (int k = SIMD_WIDTH-1 ; k >= 0; k--)begin 
                  if(k == 0) begin 
                    $fwrite(f_test_add,"%h\n",o_data[k]);
                  end else begin 
                    $fwrite(f_test_add,"%h,",o_data[k]);
                  end
              end
          end else if (op ==1) begin 
                for (int k = SIMD_WIDTH-1 ; k >= 0; k--)begin 
                    //$display("%h", o_data[k]);
                  if(k == 0) begin 
                    $fwrite(f_test_sub,"%h\n",o_data[k]);
                  end else begin 
                    $fwrite(f_test_sub,"%h,",o_data[k]);
                  end
              end
        end
          #T ; 
          //`assert_equals(u_proc.state, u_proc.FINISHED, "Should be on write")   
          #(2*T); 
          // wait until it turns back to idle
          //$finish; 
        end
      end
      /* ------------------------       MATMUL  TESTING    ------------------------ */ 
      i_rstn =0 ; 
      i_en = 0  ;
      #T ;  
      i_rstn = 1 ;  
      
      $readmemh("py/tests/proc/matmul/mat.txt",mat_data);
      $readmemh("py/tests/proc/matmul/vec.txt",vec_data);
      #T ; 
      i_en = 1 ; 
      i_grant_rd =1 ; 
      i_grant_wr =1 ; 
      i_cmd.op =2 ; 
      i_cmd.count = 16 ; 
      i_cmd.addr_0 = 0 ;
      i_cmd.addr_1 = 0 ;
      i_cmd.wr_addr = 100 ; 
      #T ; 
      // ld cmd 
      `assert_equals(u_proc.state , u_proc.LD_CMD, "Processor should be loading " ) // loading addr of 1st 
      #T; 
      while (!o_finish) begin 
          if (u_proc.state == u_proc.FETCH1 || u_proc.state == u_proc.PRE_FETCH) begin 
              for (int i = 0 ; i < SIMD_WIDTH; i ++ ) begin 
                i_data[i]  = mat_data[(o_addr-i_cmd.addr_0)+(SIMD_WIDTH-i-1)];
              end 
              if (u_proc.state == u_proc.FETCH1) begin 
                $display ("[FETCH1]: Trying to read data: %d",o_addr); 
              end
              else begin 
                $display ("[PRE_FETCH]: Trying to read data: %d",o_addr); 
              end
          end   
          else if (u_proc.state == u_proc.FETCH2) begin 
              for (int i = 0 ; i < SIMD_WIDTH; i ++ ) begin 
                i_data[i]  = vec_data[(o_addr-i_cmd.addr_1)+(SIMD_WIDTH-i-1)];
              end
          end 
          else if (u_proc.state == u_proc.WRITE ) begin 
              $display ("o_addr: %d",o_addr); 
              $display ("o_data: %h",o_data);
          end
          #T; 

      end
      // fetch 
       
      $finish ;
      
    end
endmodule

`timescale 1ns / 1ps
`include "array.sv"
module tb_array();
  localparam T = 10 ; 
  localparam UNIT_SIZE = 32;
  // Inputs
  logic [1:0] opcode;
  logic clk ;  
  logic rstn ;
  // Outputs
  logic i_en ; 
  logic valid;
  logic [UNIT_SIZE-1:0] res  [5];
  logic [5* UNIT_SIZE-1:0] arr_res;
  logic [UNIT_SIZE-1:0] o_res [5];
  logic [UNIT_SIZE-1:0] inp0 [5];
  logic [UNIT_SIZE-1:0] inp1 [5];
  always_comb begin 
      for (int i =0  ; i < 5; i++) begin 
          o_res[i] = arr_res[i*UNIT_SIZE +: UNIT_SIZE] ;
      end
  end

  // Instantiate the Unit Under Test (UUT)
simd_array #(.UNIT_SIZE(32), .WIDTH(5)) u_arr (
    .i_clk  ( clk ),  
    .i_rstn ( rstn ), 
    .i_op   ( opcode ), 
    .i_a ( inp0 ),  
    .i_b ( inp1 ),  
    .i_run  ( i_en ),  
    .o_valid( valid ), 
    .o_res  ( arr_res)
);
initial begin 
    forever begin 
        clk = 0 ; 
        #(T/2) ; 
        clk =1 ; 
        #(T/2) ; 
    end
end
initial begin 
        $dumpfile("sim/array_tb.vcd");
        $dumpvars(0, tb_array);
end
logic [4:0][31:0] expected_result_1 ; 
logic [4:0][31:0] expected_result_2; 
  initial begin
    // Initialize inputs
    opcode = 0; // ADD
    opcode = 1; // SUB 
    opcode = 2; // (MAC) 
    rstn = 0 ; 
    for (int i = 0 ; i < 5; i++) begin
      inp0[i] = 0 ;
      inp1[i] = 0 ;
    end
    #T ; 
    rstn = 1 ;
    i_en = 0 ; 
    // Wait for a few clock cycles
    #T;
    opcode = 0;
    for (int i = 0 ; i <5; i++) begin
      inp0[i] = i ;
      inp1[i] = i ;
      res [i] = inp0[i] + inp1[i];
    end
    i_en =1 ; 
    #T; 
    $display ("HELLLOWOOW   %h", arr_res); 
    if ({o_res[4], o_res[3], o_res[2],o_res[1], o_res[0]} !={res[4], res[3], res[2], res[1], res[0]}) begin

      for (int i = 0 ; i < 5 ; i++) begin 
        $display("Addition test case failed! Expected: %h, Actual: %h",res[i], o_res[i]); 
      end

    end  else begin
      for (int i = 0 ; i < 5 ; i++) begin 
        $display("Addition test case succeeded! Expected: %h, Actual: %h",res[i], o_res[i]); 
      end
    end

    i_en= 0 ; 
    #T; 
    // Subtract test case 
    i_en = 1; 
    opcode = 1;
    for (int i = 0 ; i < 5; i++) begin
      inp0[i] = 3*(i+2) ;
      inp1[i] = 4*i ;
      res [i] = inp0[i] - inp1[i];
    end
    #T;
    if ({o_res[4], o_res[3], o_res[2],o_res[1], o_res[0]} !={res[4], res[3], res[2], res[1], res[0]}) begin
      for (int i = 0 ; i < 5 ; i++) begin 
        $display("Addition test case failed! Expected: %h, Actual: %h",res[i], o_res[i]); 
      end
    end else begin
      for (int i = 0 ; i < 5 ; i++) begin 
        $display("subtraction test case succeeded! Expected: %h, Actual: %h",res[i], o_res[i]); 
      end
    end
    i_en = 0 ; 
    #T; 

    // MAC case
    rstn = 0 ;  
    i_en = 0 ; 
    opcode = 2 ;
    #T ; 
    rstn = 1;  
    
    #T ;
    i_en = 1 ; 
    inp0[0] = 4;
    inp1[0] = 2;
    inp0[1] = 6;
    inp1[1] = 3;
    inp0[2] = 8;
    inp1[2] = 4;
    inp0[3] = 10;
    inp1[3] = 5; 
    inp0[4] = 12; 
    inp1[4] = 14; 
    #T;  
    i_en =0 ; 
    $display("disabled en" ) ;
    expected_result_1 = {32'd168, 32'd50, 32'd32, 32'd18, 32'd8}; 
    #T ; 
    $display ("here" ) ; 
    // result 

    for (int i = 0; i < 5; i++) begin
        if (o_res[i] == expected_result_1[i])begin 
        $display("Unit %0d: MAC Test 1 PASSED", i);
        $display ("Expected: %d ,Actual result: %d" , expected_result_1[i] ,o_res[i]) ;
    end
        else begin 
        $display("Unit %0d: MAC Test 1 FAILED", i); 
        $display ("Expected: %d ,Actual result: %d" , expected_result_1[i] ,o_res[i]) ;
    end
    end  
    #T; 
    inp0[0] = 2;
    inp1[0] = 3;
    inp0[1] = 4;
    inp1[1] = 4;
    inp0[2] = 6;
    inp1[2] = 5;
    inp0[3] = 8;
    inp1[3] = 6;
    inp0[4] = 91; 
    inp1[4] = -1; 
    i_en = 1;  
    #T ; 
    i_en = 0 ; 
    expected_result_2 = {32'd77, 32'd98, 32'd62, 32'd34, 32'd14}; 
    #T ; 
    // result 2 

    for (int i = 0; i < 5; i++) begin
        if (o_res[i] == expected_result_2[i]) begin 
            $display("Unit %0d: MAC Test 2 PASSED", i);
            $display ("Expected: %d ,Actual result: %d" ,expected_result_2[i],  o_res[i]) ;
        end
    else begin 
        $display("Unit %0d: MAC Test 2 FAILED", i);
            $display ("Expected: %d ,Actual result: %d" ,expected_result_2[i],  o_res[i]) ;

    end
    end  

    $display("Testbench completed successfully!");
    $finish;
  end

endmodule


`timescale 1ns / 1ps
`include "array.sv"
module tb_array();
  localparam UNIT_SIZE = 32;
  // Inputs
  logic [1:0] opcode;
  logic [UNIT_SIZE*5-1:0] i_in1;
  logic [UNIT_SIZE*5-1:0] i_in2;

  // Outputs
  logic [UNIT_SIZE*5-1:0] o_res;

  logic [UNIT_SIZE-1:0] res  [5];
  logic [4:0][UNIT_SIZE-1:0] inp0 ;
  logic [4:0][UNIT_SIZE-1:0] inp1 ;
  assign i_in1 = {inp0[4], inp0[3], inp0[2], inp0[1], inp0[0]};
  assign i_in2 = {inp1[4], inp1[3], inp1[2], inp1[1], inp1[0]};
  // Instantiate the Unit Under Test (UUT)
  array#(.UNIT_SIZE(UNIT_SIZE)) dut (
    .opcode(opcode),
    .i_in1(i_in1),
    .i_in2(i_in2),
    .o_res(o_res)
  );
  initial begin 
        $dumpfile("sim/array_tb.vcd");
        $dumpvars(0, tb_array);
end
  initial begin
    // Initialize inputs
    opcode = 0; // ADD
    opcode = 1; // SUB
    opcode = 2; // MUL
    for (int i = 0 ; i < 5; i++) begin
      inp0[i] = 0 ;
      inp1[i] = 0 ;
    end

    // Wait for a few clock cycles
    #10;
    opcode = 0;
    for (int i = 0 ; i <5; i++) begin
      inp0[i] = i ;
      inp1[i] = i ;
      res [i] = inp0[i] + inp1[i];
    end
    #10;
    if (o_res !== {res[4], res[3], res[2], res[1], res[0]}) begin
      $display("Addition test case failed! Expected: 32'h02020202, Actual: %h", o_res);
    end  else begin
      $display("Addedition successfully completed");
      $display("i_in = %h , i_in2 = %h , o_res = %h", i_in1, i_in2, o_res);
    end


    // Subtract test case
    opcode = 1;
    for (int i = 0 ; i < 5; i++) begin
      inp0[i] = 3*(i+2) ;
      inp1[i] = 4*i ;
      res [i] = inp0[i] - inp1[i];
    end
    #10;
    if (o_res !== {res[4], res[3], res[2], res[1], res[0]}) begin
      $display("Subtraction test case failed! Expected: 32'h01010101, Actual: %h", o_res);
    end else begin
      $display("Subtraction successfully completed");
      $display("i_in = %h , i_in2 = %h , o_res = %h", i_in1, i_in2, o_res);
    end
    // Matrix multiplication test case
    opcode = 2;
    // Give me a vector with -2 ,1 ,1 in hex format each with length 32bits 
    inp1= {32'hFFFFFFFE , 32'h00000001, 32'hFFFFFFFF , 64'd0}; // input vector -2 1 -1
    inp0= {32'hFFFFFFFF , 32'd0 , 32'd1 , 32'd2, 32'd3}; // input toep matrix. (-1 0 1 2 3 ) // 3x3


    // Matrix multiplication test case
    opcode = 2;
    // Give me a vector with -2 ,1 ,1 in hex format each with length 32bits 
    inp1= {32'hFFFFFFFE , 32'h00000001, 32'hFFFFFFFF , 64'd0}; // input vector -2 1 -1
    inp0= {32'hFFFFFFFF , 32'd0 , 32'h00000001, 32'h00000002, 32'h00000003}; // input toep matrix. (-1 0 1 2 3 ) // 3x3
    // set o_res to output of matrix multiplication between (1,2,3; 0,1,2; -1,0,1) and (-2,1,-1)
    res[0] = 32'hFFFFFFFD; // -2*1 + 2*1 + -1*3 = -3 {y0} 
    res[1] = 32'hFFFFFFFF; // -2 * 0 + 1 * 1 + -1 *2 = -1 {y1} 
    res[2] = 32'd1; // -2 * -1 + 1 * 0 + -1 = 1 {y2} 

    #10;
    if (o_res[5*UNIT_SIZE-1-:3*UNIT_SIZE] !== {res[0], res[1], res[2]}) begin
      $display("Matrix multiplication test case failed! Expected: %h , %h , %h , Actual: %h , %h , %h",
          res[0] , res[1], res[2], o_res[5*UNIT_SIZE-1-:UNIT_SIZE] , o_res[4*UNIT_SIZE-1-:UNIT_SIZE] , o_res[3*UNIT_SIZE-1-:UNIT_SIZE]);
    end

    $display("Testbench completed successfully!");
    $finish;
  end

endmodule


`include "defines.sv"
//`include "cam/cam.v"

`timescale 1ns / 1ps
`define  push_back(val) \ 
begin \ 
    write_enable = 1;  \ 
    write_data = val ;  \
    #T ;  \ 
    write_enable=  0 ;  \ 
    while(write_busy) begin  \ 
        #T;  \ 
    end \ 
end 
`define delete(addr) \ 
begin \ 
    write_delete = 1       ; \ 
    write_addr =  addr     ; \ 
    # T                    ; \
    write_delete = 0       ; \ 
    while(write_busy) begin  \ 
        #T                 ; \
    end  \
end 
module tb_cam; 
localparam T = 10 ; 
// cam Parameters
localparam DATA_WIDTH   =  $bits(cmd_id_t) + $clog2(`PROC_COUNT)  ;
localparam ADDR_WIDTH   =   $clog2(`PROC_COUNT) +1 ;
localparam CAM_STYLE    = "SRL";
localparam SLICE_WIDTH  =  4;
//localparam DATA_WIDTH   =  64;
//localparam ADDR_WIDTH   =  5;
//localparam CAM_STYLE    = "SRL";
//localparam SLICE_WIDTH  =  4;
// cam Inputs
logic clk;
logic rst;
logic [ADDR_WIDTH-1:0]  write_addr;
logic [DATA_WIDTH-1:0]  write_data;
logic write_delete;
logic write_enable;
logic [DATA_WIDTH-1:0]  compare_data;

// cam Outputs
logic write_busy;
logic [2**ADDR_WIDTH-1:0]  match_many;
logic [2**ADDR_WIDTH-1:0]  match_single;
logic [ADDR_WIDTH-1:0]  match_addr;
logic match;
cam #(
    .DATA_WIDTH(DATA_WIDTH) ,
    .ADDR_WIDTH(ADDR_WIDTH) ,
    .CAM_STYLE(CAM_STYLE) ,
    .SLICE_WIDTH (SLICE_WIDTH)
) 
 u_cam (
    .clk                     ( clk            ),
    .rst                     ( rst            ),
    .write_addr              ( write_addr     ),
    .write_data              ( write_data     ),
    .write_delete            ( write_delete   ),
    .write_enable            ( write_enable   ),
    .compare_data            ( compare_data   ),
    .write_busy              ( write_busy     ),
    .match_many              ( match_many     ),
    .match_single            ( match_single   ),
    .match_addr              ( match_addr     ),
    .match                   ( match          )
);

initial begin  
    $dumpfile("sim/tb_cam.vcd");
    $dumpvars(0, u_cam);
end
initial begin 
    forever begin 
        clk = 0 ; 
        #(T/2) ;  
        clk = 1 ; 
        #(T/2) ;  
    end           
    rst = 0 ; 
    write_enable = 0 ; 
    write_delete = 0 ; 
    write_addr = 0 ;  
    compare_data = 0 ;
end
cmd_id_t cmd_id ; 
logic [$clog2(`PROC_COUNT)-1:0] proc_id; 
initial begin 
    #T; 
    rst = 1; 
    #T; 
    rst = 0; 
    write_addr = 0 ; 
    cmd_id = 1; 
    proc_id = 2 ;
    // Problem with 0 , 0 
    #(20*T);
    // Check for matches 
    `assert_equals(match , 0 , "Nothing written to cam, so there should be no match" )
    $display("%b", match_many) ;  
    $display("%b", match_single) ; 
    $display ("%h", match_addr) ;  
    # T; 
    //push_back
    write_data  = {cmd_id , proc_id} ; 
     write_addr  =2 ; 
    `push_back(write_data)   
    write_addr = write_addr + 1; 
    #T ; 
    compare_data = {cmd_id , proc_id};  
    #T ; 
    $display("%b", match_many) ;  
    $display("%b", match_single) ; 
    $display ("%h", match_addr) ; 
    `assert_equals(match , 1 , "Searching with cmd_id and proc_id" )
    compare_data = {cmd_id ,2'd3}; 
    #T ; 
    $display("%b", match_many) ;  
    $display("%b", match_single) ; 
    $display ("%h", match_addr) ; 
    `assert_equals(match , 1 , "Searching with correct cmd_id and incorrect proc_id" )
    compare_data = {4'd11, proc_id}; 
    #T; 
    $display("%b", match_many) ;  
    $display("%b", match_single) ; 
    $display ("%h", match_addr) ; 
    `assert_equals(match , 1 , "Searching with correct proc_id and incorrect cmd_id" )
    compare_data ={2'd0, proc_id, 2'd0  };  
    #T ; 
    $display("%b", match_many) ;  
    $display("%b", match_single) ; 
    $display ("%h", match_addr) ; 
    `assert_equals(match , 0 , "should'nt exist" )
    compare_data = 0 ; 
    #T ; 
    $display("%b", match_many) ;  
    $display("%b", match_single) ; 
    $display ("%h", match_addr) ; 
    `assert_equals(match , 0 , "should'nt exist" )
    $finish; 
end



endmodule 
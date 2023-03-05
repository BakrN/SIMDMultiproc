`include "scoreboard.sv"
`define QUOTE(q) `"q`"
int TEST_NO = 0 ; 
function void assert_equals(input logic signal1, input logic signal2, input string message);
  
  if (signal1 !== signal2) begin
    $error("Assertion failed: Signal1:%d , signal2: %d , ", signal1, signal2, message);  
  end else begin 
  end
endfunction

`define dump_scoreboard(inst) \
  begin \ 
  entry_t t;\
  $display("dumping scoreboard contents");      \
  for (integer i = 0 ; i < `PROC_COUNT; i ++) begin \
  t= inst.map[i]; \
  $display("At index %d Key: %d, Value: %d", i , t.cmd_id, t.proc_id) ;  \ 
  end \
  end

module tb_scoreboard; 

localparam T = 10;
// scoreboard Inputs
logic   i_clk;
logic   i_rstn;
entry_t i_entry;
logic i_write;
logic i_flush;
logic i_read;
logic [$clog2(`PROC_COUNT)-1:0] o_id;
logic o_exists;
logic o_ack  ; 
scoreboard  u_scoreboard (
    .i_clk                      ( i_clk                       ),
    .i_rstn                     ( i_rstn                      ),
    .i_entry                    ( i_entry                     ), 
    .i_write                    ( i_write                     ),
    .i_flush                    ( i_flush                     ),
    .i_read                     ( i_read                      ),
    .o_id                       (  o_id                       ),
    .o_ack                      (  o_ack                      ) , 
    .o_exists                   ( o_exists                    )
); 
// starting initializations
 
initial begin
    forever begin
    i_clk = 0;
    #(T/2) ; 
    i_clk = 1;
    #(T/2) ; 
    end
end
initial begin 
    i_rstn = 1;
    i_entry.cmd_id = 1 ; 
    i_entry.proc_id = 3;  
    i_write = 0; 
    i_flush = 0;
    i_read = 0; 
    // seting up for testing
    for (integer i = 0 ; i < 4; i++) begin
        entry_t t ; 
        t.cmd_id = i ; 
        t.proc_id = i+1 ; 
        u_scoreboard.map[i] =  t ; 
    end 
end
// Dumping out waveform 
initial begin 
    $dumpfile("test.vcd");
    $dumpvars(0, u_scoreboard);
end

// Testing the scoreboard
initial begin 
    #T ; 
    /* ---------------------- Dump out scoreboard contents ---------------------- */
    `dump_scoreboard(u_scoreboard)  
    /* ------------------------------- Test Reads ------------------------------- */ 
    // test read entries
    for (integer i = 0 ; i < `PROC_COUNT; i++) begin 
      i_entry.cmd_id = i ;  
      i_read = 1;
      #T 
      i_read = 0 ; 
      // should read 2 
      #(20*T) ; 
      $finish ; 
      //while (!o_ack)  begin  
      //  #T; 
      //end 
      assert_equals(o_id , i+1, "Incorrect valid (ID) for key ") ; 
      assert_equals(o_exists, 1, "Couldn't find key") ;   
    end
    /* ----------------------------- Testing Writes ----------------------------- */
    
    /* ----------------------- Testing reads after writes ----------------------- */

    /* ------------------------------ Testing flush ----------------------------- */

    /* ----------------------------- Testing Writes ----------------------------- */
  

    $finish ; 
end

endmodule
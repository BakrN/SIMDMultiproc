`include "scoreboard.sv"
`define QUOTE(q) `"q`"
int TEST_NO = 0 ; 

`define assert_equals(signal1, signal2, message) \
  if (signal1 !== signal2) begin \
    $error("Assertion failed: signal1:%d , signal2:%d ,%s", signal1, signal2, message); \
  end else begin \
    $display("signal1: %d and signal2: %d were equal", signal1, signal2); \
  end

  

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
    u_scoreboard.valid_table = 4'hF; 
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
    for (integer i = 0 ; i < `PROC_COUNT; i=i+1) begin 
      i_entry.cmd_id = i ;  
      i_read = 1;
      #T ;
      // should read 2  
      while (!o_ack)  begin  
        #(T/2);  
      end 

      `assert_equals(o_id , (i_entry.cmd_id + 1) % `PROC_COUNT, "Incorrect value for key")  ; 
      `assert_equals(o_exists, 1, "Key ddoesn't exist.")  ; 
      i_rstn = 0 ; 
      i_read = 0 ; 
      #(2*T) ;   
      i_rstn =1 ; 
      u_scoreboard.valid_table = 4'hF; // revalidate entries 
    end 
    u_scoreboard.valid_table = 4'd0 ;  // flush
    /* ----------------------------- Testing Writes ----------------------------- */
    // Write keys 4 
    i_entry.cmd_id = 4; 
    i_entry.proc_id = 1; 
    
    i_write = 1 ;
    #T ; 
    i_write = 0 ; 
    while (!o_ack)begin 
      #(T/2) ;
    end 
    #T ; 
    // write 6 
    i_entry.cmd_id = 6; 
    i_entry.proc_id = 2; 
    i_write = 1 ;
    #T ; 
    i_write = 0 ; 
    while (!o_ack)begin 
      #(T/2) ;
    end 
    #T ; 
    // write 8 
    i_entry.cmd_id = 8; 
    i_entry.proc_id = 3; 
    i_write = 1 ;
    #T ; 
    i_write = 0 ; 
    while (!o_ack)begin 
      #(T/2) ;
    end 
    #(2*T) ; 

    /* ----------------------- Testing reads after writes ----------------------- */
    i_entry.cmd_id = 8 ; 
    `dump_scoreboard(u_scoreboard) 
    // test read 8 
    i_read = 1; 
    #T ; 
    i_read = 0 ; 
    while (!o_ack) begin 
      #(T/2); 
    end
    `assert_equals(o_id , 3 , "test") ; 
    `assert_equals(o_exists,1 , "test") ; 

    /* ------------------------------ Testing flush ----------------------------- */


    /* ----------------------------- Testing Writes ----------------------------- */
  

    $finish ; 
end

endmodule
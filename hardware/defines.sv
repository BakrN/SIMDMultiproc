`ifndef DEF_HEAD
`define DEF_HEAD


`define PROC_COUNT  4
`define MAX_CMDS `PROC_COUNT*2 // Maximum amount of commands that could be stored in CAM 
`define USIZE 32 
`define BUS_W 128
`ifndef MEM_SIZE
`define MEM_SIZE 1000 // 256  cmd
//`define MEM_SIZE 100000 // 512 cmd
`endif

typedef logic[23:0] addr_t ;// shaerd mem address  
typedef logic[3:0] cmd_id_t; 

typedef struct packed{   
        cmd_id_t         cmd_id; 
        logic[$clog2(`PROC_COUNT)-1:0]            proc_id;  
} entry_t ; // Entries for cam



// opcodes: add , sub , multiply , reduce 
typedef enum logic [1:0] {ADD_OP, SUB_OP, MAC} opcode_t; 
// Write: contains addr or index and size of data to overwrite
// set info:  set size 


typedef struct packed{
        logic [1:0]  op ;  // add sub mul2x mul3x
        addr_t addr_0;    // Operand 0 address
        addr_t addr_1;    // Operand 1 address 
        logic [7:0] count;  // size of operation (how many elements) 
        addr_t wr_addr  ;  // result writeback_addr. 0 for addr_0 , 1 for addr_1 
} cmd_info_t ;
typedef struct packed{ 
        cmd_id_t   id ; // cmd id 
        cmd_id_t   dep; // dependency id
        cmd_info_t info ; 
} cmd_t; // commands enqueued by controller   

// Dependent cmd waiting for thing to finish , exec_cam

typedef struct packed { 
      cmd_id_t id ; 
      cmd_id_t dep ; // dep id 
      logic[$clog2(`MAX_CMDS)-1:0] entry_idx;// position of cmd info stored instr 
} dep_cmd_t ; 



`define assert_equals(signal1, signal2, message) \
  if (signal1 !== signal2) begin \
    $error("Assertion failed: signal1:%d , signal2:%d ,%s", signal1, signal2, message); \
    $finish; \
  end else begin \
    $display("signal1: %d and signal2: %d were equal", signal1, signal2); \
  end

`endif 

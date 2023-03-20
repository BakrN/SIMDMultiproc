`ifndef DEF_HEAD
`define DEF_HEAD


`define PROC_COUNT  4
`define UNIT_SIZE   4 // int32 
`define MEM_SIZE 4096

typedef logic[23:0] addr_t ;// shaerd mem address  
typedef logic[3:0] cmd_id_t; 

typedef struct packed{   
        cmd_id_t         key; 
        logic            val;  
} entry_t ; // Entries for scoreboard



// OPCODES: add , mul , ld  , set info , write , sub 
typedef enum logic {INSTR_LD, INSTR_INFO} opcode_t; 
// Write: contains addr or index and size of data to overwrite
// set info:  set size, and which to data to overwrite
typedef struct packed { 
        logic [$clog2(2**$bits(addr_t)/`UNIT_SIZE)-1:0] count;  // How many elements 
        logic [1:0] op ; // operation . 0 for add ,  1 for sub , 2 for mul 
        logic overwrite ; // 0: overwrite addr_0 , 1: overwrite addr_1 ;
} instr_info_t ; // this is only valid for instr info case. Otherwise it just the address

typedef struct packed{ 
        opcode_t  opcode ; 
        instr_info_t payload;  // For instr info: 19 is for size , op (add mul or sun), which to overwrite
}instr_t;   // Instruction run on each proc
 


typedef struct packed{ 
        cmd_id_t id ; // cmd id 
        cmd_id_t dep; // dependency id
        addr_t addr_0;    
        addr_t addr_1;
        logic [$clog2(2**$bits(addr_t)/`UNIT_SIZE)-1:0] count;// size of operation (how many elements) 
        logic [1:0]  op ; // add mul sub    
        logic wr_addr ;  // result writeback_addr. 0 for addr_0 , 1 for addr_1 

} cmd_t; // commands enqueued by controller   

`endif 
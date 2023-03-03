
parameter PROC_COUNT = 4 ; 
parameter ID_WIDTH =   4; 

typedef struct packed{  
        logic [ID_WIDTH-1:0] cmd_id; 
        logic [$clog2(PROC_COUNT)-1:0] proc_id ; 
} entry_t ; 
typedef logic[3:0] id_t; 

// OPCODES: add , mul , ld  , set info , write , sub 
typedef enum logic [2:0] {INSTR_ADD, INSTR_MUL, INSTR_LD, INSTR_INFO, INSTR_WRITE, INSTR_SUB} opcode_t; 
// Write: contains addr or index and size of data to overwrite
// set info:  set size, and which to data to overwrite

typedef struct packed{ 
        logic [3:0] id ;
        opcode_t  opcode ; 
        logic [24:0] info;  
}instr_t;   // change this later name to instr_t

typedef struct packed{ 
        logic[63:0] data; 
} cmd_t; // commands enqueued by controller   

typedef logic[23:0] addr_t ;// shaerd mem address 




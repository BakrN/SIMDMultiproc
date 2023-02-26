
parameter PROC_COUNT = 4 ; 
parameter ID_WIDTH = 4; 
typedef struct packed{  
        logic [ID_WIDTH-1:0] cmd_id; 
        logic [$clog2(PROC_COUNT)-1:0] core_id ; 
} entry_t ; 
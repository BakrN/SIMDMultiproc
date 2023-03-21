// To resolve dependencies (access with request id) (adds dependencies) (flush when cmd completed)
// Used by issuer (indexed by a request's id) 
// keeps track of cmds being executed 
// COUNT should be a power of 2 
// Key: cmd_id  Value: proc id 
`include "defines.sv"
/*
*   @brief scoreboard module
*   @details This module implements an associative array (hashmap) with linear probing for collision resolution. 

*/ 
module scoreboard  (
    i_clk , 
    i_rstn, 
    i_entry,  
    i_write, // or update
    i_flush, 
    i_read , 
    o_ack, // valid result
    o_val , 
    o_exists
) ; 
    // STATES   
    localparam IDLE = 2'b0;
    localparam OUT = 2'b11; 
    // Search strats 
    localparam WRITE = 2'b01; 
    localparam READ = 2'b10;  
    
    
    input i_clk ;  
    input i_rstn; 
    input entry_t i_entry;  
    
    input i_write; // For adding entry to scoreboard
    input i_flush; // for removing entry from scoreboard  
    input i_read ; // for checking if key exists and if exists retrieve proc id  
    output o_exists; 
    output o_ack ; 
    output [$bits(current_entry.val)-1:0] o_val ; 
    entry_t map [`PROC_COUNT-1:0]  ;  

    logic [`PROC_COUNT-1:0] valid_table ;  // table containing valid entries 
    entry_t current_entry ;//,base_entry;
    assign current_entry = map[probe_idx] ;
    assign o_val = current_entry.val ; 
    logic [1:0] state ; 
    logic [1:0] next_state; 
    logic [$clog2(`PROC_COUNT)-1:0] probe_idx; 
    logic [$clog2(`PROC_COUNT)-1:0] base_index; 

    logic found , reinit ,flush; 
    assign base_index = i_entry.key%`PROC_COUNT; 
    //logic [$clog2(`PROC_COUNT)-1:0] r_idx; 
    //logic [$clog2(`PROC_COUNT)-1:0] r_probe_idx_original ;
    // state machine  
    
    // FSM 
    always_ff @(posedge i_clk or negedge i_rstn) begin 
        if (!i_rstn ) begin 
            state <= IDLE ; 
            found = 0 ; 
            valid_table = 0 ; 
        end 
        else begin 
            case(state) 
                IDLE: begin  
                    state <= next_state ; 
                    found <= 0 ;   
                end
                READ: begin    
                    // if looped aroung to original index without finding key then stop  
                    if ((!reinit && probe_idx == base_index) || !valid_table[probe_idx]) begin 
                        found <= 0 ; 
                        state <= OUT; 
                        flush <= 0 ; 
                    end
                    // if found 
                    else if (current_entry.key== i_entry.key) begin 
                        if (flush) begin 
                            valid_table[probe_idx] = 0 ; 
                        end 
                        found <= 1; 
                        state <= OUT ;  
                        flush <= 0 ;
                        
                    end
                    // IF occupied move forward 
                    else begin 
                        probe_idx <= probe_idx + 1 ; 
                        reinit <= 0 ;
                    end  

                end 
                WRITE: begin // Behaviour assumes you have at least 1 garunteed slot  otherwise it will be stuck in this state
                    if (!valid_table[probe_idx] )  begin  
                    // found free entry now write
                        map[probe_idx] <= i_entry; 
                        state <= OUT ;
                        valid_table[probe_idx] = 1; 
                    end  else  
                        probe_idx <= probe_idx + 1 ; 
                end
                OUT: begin 
                    state <= IDLE; 
                end
                default: 
                    state <= IDLE ; 
            endcase
        end
    end
    // on change of state 
    always @(base_index) begin   
        if (state ==IDLE) begin 
            probe_idx = base_index;  
            reinit <= 1;   
        end
    end
    always @(posedge i_flush) begin  
        flush <= 1 ; 
    end
    // Calculate next entry 
    always_comb begin
        if (i_write) begin 
            next_state = WRITE ; 
        end else if (i_read | i_flush ) begin 
            next_state = READ;   
        end  else begin 
            next_state = IDLE;  
        end 
    end
  
    assign o_ack = (state == OUT) ? 1 : 0;  
    assign o_exists = found ;  
    
endmodule 


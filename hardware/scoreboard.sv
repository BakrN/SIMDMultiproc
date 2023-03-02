// To resolve dependencies (access with request id) (adds dependencies) (flush when cmd completed)
// Used by issuer (indexed by a request's id) 
// keeps track of cmds being executed 
// COUNT should be a power of 2 
`include "defines.svh"
/*
*   @brief scoreboard module
*   @details This module implements an associative array (hashmap) with linear probing for collision resolution. 
*/ 
module scoreboard  (
    i_clk , 
    i_rstn, 
    i_entry,  
    i_write, 
    i_flush, 
    i_read , 
    o_id   , 
    o_exists
) ; 
    localparam s_IDLE = 2'b0;
    localparam s_get_free = 2'b01; 
    localparam s_read = 2'b10; 
    localparam s_found = 2'b11; 
    input i_clk ;  
    input i_rstn; 
    input entry_t i_entry;  
    // For adding entry to scoreboard
    input i_write;  
    // for removing entry from scoreboard 
    input i_flush;  
    // for checking if key exists and if exists retrieve proc id 
    input i_read ;  
    output logic [ID_WIDTH-1:0] o_id  ; 
    output o_exists; 
    entry_t map [PROC_COUNT-1:0]  ;   
    logic r_state ; 
    logic [$clog2(PROC_COUNT)-1:0] r_idx; 
    logic not_found ; 
    logic reinit ; 
    logic [$clog2(PROC_COUNT)-1:0] r_probe_idx; 
    logic [$clog2(PROC_COUNT)-1:0] r_probe_idx_original ;
    // state machine  
    always_ff @(posedge i_clk or negedge i_rstn) begin 
        if(!i_rstn) begin 

        end else begin 
            if (i_write) begin  
                if (r_state == s_found ) begin // no overwrites (empty index)
                    map[r_idx] = i_entry;   
                    r_state   <=  s_IDLE;
                end 
            end else if(i_flush) begin 
                if (r_state ==s_found) begin 

                end else 
                    r_state <= s_read  ; 

            end else if(i_read ) begin 
                if (r_state == s_found)begin  
                     
                    r_state <= s_IDLE; 
                end else 
                    r_state <= s_read ; 
            end 
        end
    end
    // linear search 
    always_ff @(posedge i_clk or negedge i_rstn) begin 
        if (!i_rstn) 
            r_state <= s_IDLE ; 
        else begin 
            case (r_state)  
                s_get_free: begin 
                end
                s_read: begin 
                    if (reinit ) begin 
                        r_probe_idx_original <= i_entry.cmd_id % PROC_COUNT; 
                        reinit <= 0 ; 
                        if (map[i_entry.cmd_id%PROC_COUNT].cmd_id == i_entry.cmd_id) begin 
                            r_state <= s_found; 
                            r_probe_idx <= (i_entry.cmd_id % PROC_COUNT);  
                            
                            
                        end else if(map[i_entry.cmd_id%PROC_COUNT].cmd_id == 0 ) begin 
                            r_state <= s_IDLE; 
                            not_found <= 1 ; 
                        end else 
                            r_probe_idx <= (i_entry.cmd_id % PROC_COUNT)+1;   
                    end
                    else if (map[i_entry.cmd_id%PROC_COUNT].cmd_id == i_entry.cmd_id) begin 
                        r_state <= s_found; 
                    end
                    else if (map[r_probe_idx].cmd_id == 0 ) begin 
                        r_state <= s_IDLE; 
                        not_found <= 1; 
                    end
                    else  
                        if (r_probe_idx == r_probe_idx_original) begin 
                            r_state <= s_IDLE; 
                            not_found <= 1 ; 
                        end else if (r_probe_idx == PROC_COUNT-1) begin 
                            r_probe_idx <= 0 ; 
                        end else  
                            r_probe_idx <= r_probe_idx+1 ; 
                    
                end
                 
            endcase  

        end

    end
    assign o_id = map[r_probe_idx].core_id ; 
    assign o_exists = (r_state==s_found)  ? 1 : 0 ; 

endmodule ; 


// Command Issue
// cores send request here  or could poll 
// contains scoreboard 
// Has fsm send cmd // wait for ack 
`include "scoreboard.sv"
`include "defines.sv"
`include "find_first_set_bit.sv"

module issuer ( 
    i_clk, 
    i_rstn, 
    i_ack , 
    
    // fifo ports
    i_cmd ,
    o_read , 
    o_write , 
    o_cmd,
    // Proc ports
    i_finish, 
    i_busy  , 
    o_en_arr, // enable or validate instr to proc
    o_ack , 
    o_instr  
) ;  
input i_clk ;
input i_rstn ;

input i_ack ; 
input [`PROC_COUNT-1:0] i_busy ; 
input [`PROC_COUNT-1:0] i_finish; 
input [`PROC_COUNT-1:0] o_en_arr ; 
input [`PROC_COUNT-1:0] o_ack ; 
output instr_t o_instr;
// fifo ports 
input cmd_t i_cmd ; 
output logic o_read ;
output logic o_write ;
output cmd_t o_cmd ; // fifo 
// State machine 
// setup simd array  
localparam IDLE = 0 ;
localparam SIMD_SELECT = 4 ;
localparam SIMD_LD1 = 1 ;
localparam SIMD_LD2 = 2 ;
localparam SIMD_INFO = 3 ;
localparam WAIT_ACK = 5 ;
// fetching and processing from queue and checking with scoreboard 
localparam CMD_GET = 7 ; 
localparam CMD_CHECK = 8 ; // check with scoreboard
localparam CMD_WRITEBACK = 9 ; // writeback to cmd_queue if there's a dependency in scoreboard
// PROC_FINISH
localparam MAP_OP = 10 ; 
localparam SEND_ACK   = 11 ; // send ack to proc out of find_first_set_bit 
 
logic [3:0] state ; 
logic [3:0] next_state ; 
logic [$clog2(`PROC_COUNT)-1:0] selected_proc;
cmd_t next_cmd ;  // next command to execute

// Current state update logic 
always_ff @(posedge i_clk or negedge i_rstn) begin 
    if (!i_rstn) begin 
        state <= IDLE ;  
        map_flush <= 0;  
        map_read  <= 0 ; 
        map_write <= 0 ; 

    end 
    else begin 
        case (state)  
            IDLE: begin  
                if(|i_finish) begin  
                    // flush id  
                    map_flush <= 1 ; 
                    state <= MAP_LOOKUP; 
                end
                else if (~|i_busy) begin  
                    // pop last cmd from fifo
                    map_flush <= 0;  
                    map_read  <= 0 ; 
                    map_write <= 0 ; 
                    state <=  CMD_GET; 
                end else begin 
                    map_flush <= 0;  
                    map_read  <= 0 ; 
                    map_write <= 0 ; 
                end
            end
            MAP_OP: begin 
                if (map_ack) begin 
                    if(map_flush) begin 
                        state <= SEND_ACK;  
                    end 
                    else begin 

                    end
                end
            end 
            SEND_ACK: begin 
                state <= IDLE; 
            end 
            CMD_GET: begin 
                state <= CMD_CHECK;
                map_read <= 0 ; 
                next_cmd <= i_cmd; // set board search 
            end
            CMD_CHECK: begin // check dep 
                if (map_exists) begin   
                    state <= SIMD_SELECT;  
                    map_read <= 0 ; 
                end  
                else begin 
                    state <= CMD_WRITEBACK;
                end
            end
            CMD_WRITEBACK: begin 
                state <= WAIT_ACK; 
            end
            WAIT_ACK: begin 
                if (i_ack) begin  
                    state <= next_state; 
                end
            end

            SIMD_SELECT: begin 
                if (i_busy[selected_proc] == 0) begin 
                    state <= SIMD_LD1 ; 
                end
                else 
                    state <= SIMD_SELECT; 
            end  
            SIMD_LD1: begin  
                state <= WAIT_ACK;  
            end
            default: 
                state <= IDLE; 
        endcase

    end 
end

// Next state logic 
always_latch begin 
    case (state) 
        SIMD_LD1 : begin 
            next_state = SIMD_LD2 ; 
        end 
        SIMD_LD2 : begin 
            next_state = SIMD_INFO ; 
        end 
        SIMD_INFO : begin 
            next_state = IDLE; 
        end  
        CMD_WRITEBACK: begin 
            next_state = IDLE; 
        end
        
        
        
    endcase 
end  
/* ---------------------------- Priority find_first_set_bit for finished signals ---------------------------- */
logic [$clog2(`PROC_COUNT)-1:0] finish_bit_pos ;  
find_first_set_bit #(`PROC_COUNT) finished_signal_finder(
    i_finish, 
    finish_bit_pos
); 

find_first_set_bit #(`PROC_COUNT) free_proc_finder(
    ~i_busy, 
    selected_proc 
); 
/* --------------------- Scoreboard module instantiation -------------------- */

// scoreboard ports 
entry_t map_entry;
logic   map_write; 
logic   map_flush;
logic   map_read;
logic   map_value ; 
logic   map_exists ;
logic   map_ack ;
assign map_entry.cmd_id = next_cmd.dep;
scoreboard  u_scoreboard (
    .i_clk                      ( i_clk                       ),
    .i_rstn                     ( i_rstn                      ),
    .i_entry                    ( map_entry                   ), 
    .i_write                    ( map_write                   ),
    .i_flush                    ( map_flush                   ),
    .i_read                     ( map_read                    ),
    .o_id                       ( map_value                   ), 
    .o_ack                      ( map_ack                     ), 
    .o_exists                   ( map_exists                  )
); 

assign o_ack = (state==SEND_ACK) ? (`PROC_COUNT'b1 << finish_bit_pos): 0 ; 
assign o_en_arr = (state < WAIT_ACK) ?  1 :0  ; 
endmodule   

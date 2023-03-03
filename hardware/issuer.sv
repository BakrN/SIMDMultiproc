// Command Issue
// cores send request here  or could poll 
// contains scoreboard 
// Has fsm send cmd // wait for ack 
`include "scoreboard.sv"
`include "defines.svh"
module issuer ( 
    i_clk, 
    i_rstn, 
    i_cmd ,
    i_ack , 
    i_finish, 
    i_busy, 
    o_en_arr , 
    // fifo ports
    o_read , 
    o_write , 
    o_cmd,
    o_instr 
) ; 
input i_clk ;
input i_rstn ;

input i_ack ; 
input [PROC_COUNT-1:0] i_busy ; 
input [PROC_COUNT-1:0] i_finish; 
input [PROC_COUNT-1:0] o_en_arr ; 
output instr_t o_instr;
// fifo ports 
input cmd_t i_cmd ; 
output logic o_read ;
output logic o_write ;
output cmd_t o_cmd ;
// State machine 
// setup simd array  
localparam IDLE = 0 ;
localparam SIMD_SELECT = 6 ;
localparam SIMD_LD1 = 1 ;
localparam SIMD_LD2 = 2 ;
localparam SIMD_INFO = 3 ;
localparam SIMD_WRITE = 4; 
localparam WAIT_ACK = 5 ;
// fetching and processing from queue and checking with scoreboard 
localparam CMD_GET = 7 ; 
localparam CMD_CHECK = 8 ; // check with scoreboard
localparam CMD_WRITEBACK = 9 ; // writeback to cmd_queue if there's a dependency in scoreboard


logic [3:0] state ; 
logic [3:0] next_state ; 
logic [$clog2(PROC_COUNT)-1:0] selected_proc;
cmd_t next_cmd ;  // next command to execute

// Current state update logic 
always_ff @(posedge i_clk or negedge i_rstn) begin 
    if (!i_rstn) begin 
        state <= IDLE ;  
    end 
    else begin 
        case (state)  
            IDLE: begin  
                if (~|i_busy) begin  
                    // pop last cmd from fifo
                    r_state <=  CMD_GET; 
                end
            end
            CMD_GET: begin 
                r_state <= CMD_CHECK;
            end
            CMD_CHECK: begin 
                if (1) begin 
                    r_state <= SIMD_SELECT; 
                end
                else begin 
                    r_state <= CMD_WRITEBACK;
                end
            end
            CMD_WRITEBACK: begin 
                r_state <= IDLE; 
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
                    selected_proc <= selected_proc + 1 ;
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
            next_state = SIMD_WRITE ; 
        end
        SIMD_WRITE : begin 
            next_state = IDLE ; 
        end  
    endcase 
end 
/* --------------------- Scoreboard module instantiation -------------------- */
// scoreboard ports 
entry_t board_entry;
logic   board_write; 
logic   board_flush;
logic   board_read;
logic   board_value ; 
logic   board_exists ;
scoreboard  u_scoreboard (
    .i_clk                      ( i_clk                       ),
    .i_rstn                     ( i_rstn                      ),
    .i_entry                    ( board_entry             ), 
    .i_write                    ( board_write                     ),
    .i_flush                    ( board_flush                     ),
    .i_read                     ( board_read                      ),
    .o_id                       ( board_value),
    .o_exists                   ( board_exists                    )
); 
endmodule 

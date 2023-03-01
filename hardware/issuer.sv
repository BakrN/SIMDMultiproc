// Command Issue
// cores send request here  or could poll 
// contains scoreboard 
// Has fsm send cmd // wait for ack 
`include "array.v" 
`include "scoreboard.sv"
`include "defines.svh"
module issuer ( 
    i_clk, 
    i_rstn, 
    i_cmd ,
    i_busy, 
    o_en_arr , 
    o_cmd, 
) ; 
input i_clk ;
input i_rstn ;
input cmd_t i_cmd ; 
input [PROC_COUNT-1:0] i_busy ;
input [PROC_COUNT-1:0] o_en_arr ;
output instr_t o_cmd ;
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

                end
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
    endcase 
end 

endmodule 

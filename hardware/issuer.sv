// Command Issue
// cores send request here  or could poll 
// contains scoreboard 
// Has fsm send cmd // wait for ack 

// ! Doesn't take into account if queue is full 
`include "scoreboard.sv"
`include "defines.sv"
`include "find_first_set_bit.sv"
`include "fifo.sv"
`include "mem.sv"

module issuer ( 
    i_clk, 
    i_rstn, 
    i_ack_queue , 
    i_ack_proc , 
    // fifo ports
    i_cmd ,
    o_rd_queue ,  
    o_cmd,
    // Proc ports
    i_finish_proc, 
    i_busy_proc  , 
    o_en_proc, // enable or validate instr to proc
    o_ack_proc , 
    o_instr  
) ;  
input i_clk ;
input i_rstn ;

input i_ack_queue ; 
input [`PROC_COUNT-1:0] i_busy_proc ; 
input [`PROC_COUNT-1:0] i_finish_proc;  
input [`PROC_COUNT-1:0] i_ack_proc ;
output logic [`PROC_COUNT-1:0] o_en_proc ; 
output logic [`PROC_COUNT-1:0] o_ack_proc ;  
output instr_t o_instr;
// fifo ports 
input cmd_t i_cmd ; 
output logic o_rd_queue ;
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
localparam CMD_WRITEBACK = 9 ; // (put back in fifo)

// PROC_FINISH

localparam PROC_FINISH = 10 ; // Flush cmd from enq_cmd map 
localparam SEND_ACK   = 11 ; // send ack to proc out of find_first_set_bit 
 
logic [3:0] state ; 
logic [3:0] next_state ; 
logic simd_op; 
cmd_t next_cmd ;  // next command to execute

// Current state update logic 
always_ff @(posedge i_clk or negedge i_rstn) begin 
    if (!i_rstn) begin 
        state <= IDLE ;  

    end 
    else begin 
        case (state)  
            IDLE: begin  
                if(|i_finish_proc) begin  
                    // flush id  
                    //map_flush <= 1 ; 
                    state <= PROC_FINISH; 
                    finish_bit_pos <= finished_proc; 
                end
                else if (~&i_busy_proc) begin  
                    // pop last cmd from fifo
                    state <=  CMD_GET; 
                end  
            end
            PROC_FINISH: begin  
                if (map_ack && i_finish_proc[finish_bit_pos]) begin 
                    state <= SEND_ACK;  
                end 
                     
            end 
            SEND_ACK: begin 
                state <= IDLE; 
            end 
            CMD_GET: begin 
                state <= CMD_CHECK;
                next_cmd <= i_cmd; // set board search 
            end
            CMD_CHECK: begin // check dep 
                if (map_ack) begin 
                    if (!map_exists) begin   
                        state <= SIMD_SELECT;   
                        selected_proc <= free_proc;
                    end  
                    else begin 
                        state <= CMD_WRITEBACK;
                    end
                end
            end
            CMD_WRITEBACK: begin 
                state <= WAIT_ACK; 
            end
            WAIT_ACK: begin 
                if (i_ack_queue || i_ack_proc[selected_proc]&simd_op) begin  
                    state <= next_state; 
                    simd_op <= 0 ; 
                end
            end

            SIMD_SELECT: begin  // Write CMD to scoreboard
                if (i_busy_proc[selected_proc] == 0 && map_ack) begin 
                    state <= SIMD_LD1 ; 
                end
                else begin 
                    state <= SIMD_SELECT; 
                    
                end
            end  
            SIMD_LD1: begin  
                state <= WAIT_ACK;  
                 simd_op <= 1 ; 
            end
            SIMD_LD2: begin 
                state <= WAIT_ACK;
                 simd_op <= 1 ;  
            end
            SIMD_INFO: begin 
                state <= WAIT_ACK; 
                simd_op <= 1 ; 
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
/* ------------------- Logic For Instruction Generetation ------------------- */ 
assign  o_instr = (state == SIMD_LD1) ? {  INSTR_LD, next_cmd.addr_0 } 
             : (state == SIMD_LD2) ?    {  INSTR_LD, next_cmd.addr_1 }
             : (state == SIMD_INFO) ?   {  INSTR_INFO, { next_cmd.count, next_cmd.op, next_cmd.wr_addr } }
             : 0;

/* ---------------------------- Priority find_first_set_bit for finished signals ---------------------------- */
logic [$clog2(`PROC_COUNT)-1:0] finish_bit_pos, finished_proc ;  
logic [$clog2(`PROC_COUNT)-1:0] selected_proc, free_proc; // selected_proc is updated on clk cycles. so not using combinational logic 
find_first_set_bit #(`PROC_COUNT) finished_signal_finder(
    i_finish_proc, 
   finished_proc 
); 

find_first_set_bit #(`PROC_COUNT) free_proc_finder(
    ~i_busy_proc, 
    free_proc 
); 
/* --------------------- Scoreboard module instantiation -------------------- */

// scoreboard ports 
entry_t map_entry;
logic   map_write; 
logic   map_read;
logic   map_exists ;
logic   map_ack ;
//assign map_entry.cmd_id  = (map_write) ?next_cmd.id :next_cmd.dep  ;// Read dep and write id 
assign map_entry.key  = map_write ?next_cmd.id : next_cmd.dep ;// Read dep and write id  
assign map_entry.val = 0; // * Value doesn't matter 
assign map_read =      (state == CMD_CHECK) ? 1 : 0 ; 
assign map_write =      (state == SIMD_SELECT) ? 1 : 0 ;

scoreboard  u_enq_cmds (
    .i_clk                      ( i_clk                       ),
    .i_rstn                     ( i_rstn                      ),
    .i_entry                    ( map_entry                   ), 
    .i_write                    ( map_write                   ),
    .i_read                     ( map_read                    ),
    .o_ack                      ( map_ack                     ), 
    .o_exists                   ( map_exists                  )
);  
/* ------------------------ FIFO of next commands tbe ----------------------- */
// Next commands fifo -> NCF 
// Inputs
logic ncf_read;
logic ncf_in_select ; 
// Outputs
cmd_t ncf_cmd_out, ncf_cmd_in; 
logic ncf_full;
logic ncf_empty;
logic ncf_select ;  // 1 for queue write , 0 for writeback from issuer

assign ncf_read  = (state==CMD_GET) ? 1 : 0 ; 
assign ncf_write = ncf_empty ;  
assign ncf_select = (state==CMD_WRITEBACK) ? 0 : 1 ; 

fifo #(
    .WIDTH ( $bits(cmd_t)),
    .DEPTH ( `PROC_COUNT  ))
 u_next_cmds (
    .i_clk                     (        i_clk           ),       
    .i_rstn                    (        i_rstn          ),       
    .i_read                    (        ncf_read        ),       
    .i_write                   (        ncf_empty       ),        
    .i_data                    (        ncf_cmd_in      ),       
    .o_data                    (        ncf_cmd_out     ),       
    .o_fifo_full               (        ncf_full        ),       
    .o_fifo_empty              (        ncf_empty       )        
);


/* --------------------- Processor Execute Table. Contains running command ids -------------------- */
/* Processor execute table -> PET */ 
// mem Inputs
logic [$clog2(`PROC_COUNT)-1:0] pet_addr_w;
logic [$clog2(`PROC_COUNT)-1:0] pet_addr_r; 

cmd_id_t      pet_data_w;
logic pet_wr_en ;
// mem Outputs
cmd_id_t pet_cmd_data;
assign pet_addr_r = finish_bit_pos;  
assign pet_addr_w = selected_proc ; 

mem#(.DEPTH(`PROC_COUNT) , .SIZE($bits(cmd_id_t)) , .BLOCK_SIZE(1) , .ADDR_SIZE($clog2(`PROC_COUNT)))  u_mem (
    
    .i_clk                   ( i_clk     ),
    .i_addr_w                ( pet_addr_w),
    .i_data_w                ( pet_data_w),
    .i_wr_size               ( 1'b1      ),
    .i_wr_en                 ( pet_wr_en ),
    .i_addr_r                ( pet_addr_r),
    .o_data                  ( pet_cmd_data) 
);


assign o_rd_queue = ncf_write & ncf_select; 
assign o_ack_proc = (state==SEND_ACK || (state == SIMD_LD1 || state == SIMD_LD2 || state == SIMD_INFO)) ? (`PROC_COUNT'b1 << finish_bit_pos): 0; 
assign o_en_proc = (state==SIMD_SELECT && i_busy_proc[selected_proc]==0) ? (`PROC_COUNT'b1 << finish_bit_pos): 0; 


endmodule   

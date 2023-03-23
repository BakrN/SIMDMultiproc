// Command Issue
// cores send request here  or could poll 
// contains scoreboard 
// Has fsm send cmd // wait for ack 

// ! Doesn't take into account if queue is full 
`include "cam/cam.v"
`include "defines.sv"
`include "find_first_set_bit.sv"
`include "fifo.sv"
`include "mem.sv"

module issuer ( 
    i_clk, 
    i_rstn, 
    i_ack_proc , 
    // fifo ports
    i_ack_queue , 
    i_cmd ,
    i_empty_queue, 
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
input i_empty_queue; 
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
localparam CMD_GET = 7 ; // get from queue or fifo
localparam CMD_CHECK = 8 ; // check dep with scoreboard
localparam CAM_WRITE = 9; // insert cmd in cam 
localparam CMD_WRITEBACK = 10 ; // (put dependent cmd in fifo) 

// PROC_FINISH

localparam PROC_FINISH = 11 ; // Flush cmd from enq_cmd map 
localparam SEND_ACK    = 12 ; // send ack to proc out of find_first_set_bit 
 
logic [3:0] state ; 
logic [3:0] next_state ; 
cmd_t next_cmd;  // next command to execute
cmd_info_t next_cmd_info ; 
cmd_id_t current_cmd_id ,current_dep_id; 
logic cmd_source; // 0: queue , 1:fifo

assign next_cmd = {current_cmd_id, current_dep_id, next_cmd_info}; 

// Current state update logic 
always_ff @(posedge i_clk or negedge i_rstn) begin 
    if (!i_rstn) begin 
        state <= IDLE ;  
        cam_counter <= 0 ; 
        cam_nxt_addr <= 0 ;
    end 
    else begin  
        case (state)  
            IDLE: begin  
                dep_counter <= dep_count ; 
                if(|i_finish_proc) begin  
                    // flush id  
                    // map_flush <= 1 ; 
                    state <= PROC_FINISH; 
                    finish_bit_pos <= finished_proc; 
                    cmd_source <= 1 ; // check fifo
                    dep_counter <= dep_count; 
                    cam_matched_addr <= cam_match_addr ;
                end
                
                else if (~&i_busy_proc) begin  
                    // pop last cmd from fifo
                    // Priorities: if cmd finishes check fifo for any dependent  cmds
                    if (dep_fifo_empty || dep_counter == 0) begin 
                        cmd_source = 0 ; 
                    end
                    if (((!dep_fifo_empty && dep_counter>0) && cmd_source) || !i_empty_queue) begin 
                        state <=  CMD_GET;  
                        dep_counter <= dep_counter - 1; 

                    end
                    
                end  
            end
            PROC_FINISH: begin  // wait for cam entry to be deleted 
                if (!cam_write_busy) begin 
                    state <= SEND_ACK;  
                end 
                     
            end 
            SEND_ACK: begin 
                state <= IDLE; 
            end 
            CMD_GET: begin 
                if (cmd_source) begin// fifo
                    current_cmd_id <= dep_dout.id ; 
                    current_dep_id <= dep_dout.dep; 
                    
                end else begin 
                    {current_cmd_id , current_dep_id ,next_cmd_info} <= i_cmd; 
                end
                state <= CMD_CHECK;
            end
            CMD_CHECK: begin // cycle to find if there is a match or not 
                // If matched then compare it with selected finish_bit_pos
                cam_matched <= cam_match ; 
                cam_matched_addr <= match_addr ; 
                state <= CAM_WRITE ; 
                selected_proc <= free_proc;
            
                end
            end
            CAM_WRITE : begin  // adds new entry to cam if no match (source0) if source is 1 and no match then we overwrite the entry 
                if (cam_matched) begin 
                    state <= CMD_WRITEBACK; 
                end
                else begin 
                    if (!write_busy) begin 
                        // finished write and now can move on to simd_select
                        // can write to cam
                        next_cmd_info <= buf_mem[buf_addr_r][ADDR_WDITH-1:0] ; 
                        state <= SIMD_SELECT; 
                    end
                end
            end
            CMD_WRITEBACK: begin // writeback to fifo
                state <= IDLE; 
            end
            WAIT_ACK: begin 
                if (i_ack_proc[selected_proc]) begin  
                    state <= next_state; 
                end
            end

            SIMD_SELECT: begin  // Write CMD to cam
                if (i_busy_proc[selected_proc] == 0 && map_ack) begin 
                    state <= SIMD_LD1 ; 
                end
                else begin 
                    state <= SIMD_SELECT; 
                    
                end
            end  
            SIMD_LD1: begin  
                state <= WAIT_ACK;  
            end
            SIMD_LD2: begin 
                state <= WAIT_ACK;
            end
            SIMD_INFO: begin 
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
/* ------------------- Logic For Instruction Generetation ------------------- */ 
assign  o_instr = (state == SIMD_LD1) ? {  INSTR_LD, next_cmd.info.addr_0 } 
             : (state == SIMD_LD2) ?    {  INSTR_LD, next_cmd.info.addr_1 }
             : (state == SIMD_INFO) ?   {  INSTR_INFO, { next_cmd.info.count, next_cmd.info.op, next_cmd.info.wr_addr } }
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


/* ---- FIFO with commands dependent on cmds still being executed on proc - dep--- */



// fifo Inputs
logic  dep_read;
logic  dep_write;
// fifo Outputs
dep_cmd_t dep_dout, dep_din; 
logic dep_fifo_full;
logic dep_fifo_empty;
logic [$clog2(FIFO_DEPTH)-1:0] dep_counter, dep_count ;
localparam FIFO_WIDTH = $bits(dep_din); 
localparam FIFO_DEPTH  = `MAX_CMDS; // * Try decreasing the size and stall for instruction to finish on proce

fifo #( 
    .WIDTH ( FIFO_WIDTH),
    .DEPTH ( FIFO_DEPTH ))
 u_fifo (
    .i_clk                     (    i_clk           ),     
    .i_rstn                    (    i_rstn          ),     
    .i_read                    (    dep_read        ),     
    .i_write                   (    dep_write       ),     
    .i_data                    (    dep_din         ),     
    .o_data                    (    dep_dout        ),     
    .o_fifo_full               (    dep_fifo_full   ),     
    .o_fifo_empty              (    dep_fifo_empty  ),  
    .o_count                   (    dep_count       )
);
// assignment 
assign dep_din   = (current_cmd_id , current_dep_id); 
assign dep_write = (state==CMD_WRITEBACK) ? 1 : 0 ; 
assign dep_read  = (state==CMD_GET && cmd_source) ? 1 : 0 ; 

/* ------------------------- CAM - CMD_ID , PROC_ID ------------------------- */

// cam Parameters
parameter DATA_WIDTH   = $bits(cmd_id_t) + $clog2(`PROC_COUNT)  ;
parameter ADDR_WIDTH   = $clog2(`MAX_CMDS) ; 
parameter CAM_STYLE    = "SRL";
parameter SLICE_WIDTH  = $bits(cmd_id_t)    ; // only 2 slices 
 
// cam logic 
logic [$clog2(`MAX_CMDS):0]   cam_counter; 
logic [$clog2(`MAX_CMDS)-1:0] cam_matched_addr; 
logic cam_matched ; // store match value

// cam Inputs 
logic  [ADDR_WIDTH-1:0]  cam_write_addr;
logic  [DATA_WIDTH-1:0]  cam_write_data;
logic  cam_write_delete;
logic  cam_write_enable;
logic  [DATA_WIDTH-1:0]  cam_compare_data;

// cam Outputs
logic  cam_write_busy;
logic  [2**ADDR_WIDTH-1:0]  cam_match_many;
logic  [2**ADDR_WIDTH-1:0]  cam_match_single;
logic  [ADDR_WIDTH-1:0]  cam_match_addr;
logic  cam_match;
// Cam Assignments
assign cam_compare_data = (state==CMD_CHECK) ? {next_cmd.dep, 0}: ((state==CAM_WRITE)?{next_cmd.id, 0} : {0, finished_proc} ); // ! Maybe just don't start with 0 as the initial value for cmd ids or proc ids. but will test this
assign cam_write_addr   = !cmd_source ? cam_counter : cam_matched_addr;  
assign cam_write_data   = (state==PROC_FINISH) ? cam_matched_addr: {next_cmd.id , selected_proc} ;
assign cam_write_enable = (state==CAM_WRITE && (!cmd_source || (!cam_matched && cmd_source))) ? 1 : 0 ; 
assign cam_write_delete = (state==PROC_FINISH) ? 1 : 0;  
// Enable write in 2 cases 
// Came from queue (regardless of cam_matched)
// came from fifo (and found original ad) and no longer match

cam #(
    .DATA_WIDTH  ( DATA_WIDTH   ),
    .ADDR_WIDTH  ( ADDR_WIDTH   ),
    .CAM_STYLE   ( CAM_STYLE    ),
    .SLICE_WIDTH ( SLICE_WIDTH  ))
 u_enq_cmds (           /// enqueued commands module
    .clk                     ( i_clk            ),
    .rst                     ( ~i_rstn            ),
    .write_addr              ( cam_write_addr     ),
    .write_data              ( cam_write_data     ),
    .write_delete            ( cam_write_delete   ),
    .write_enable            ( cam_write_enable   ),
    .compare_data            ( cam_compare_data   ),
    .write_busy              ( cam_write_busy     ),
    .match_many              ( cam_match_many     ),
    .match_single            ( cam_match_single   ),
    .match_addr              ( cam_match_addr     ),
    .match                   ( cam_match          )
);

// Storing payloads of cmds . Standard MEM 
localparam buf_depth = 2**ADDR_WIDTH;
localparam buf_width = $bits(cmd_info_t) 
// mem Inputs
logic [ADDR_WIDTH-1:0]  buf_addr_w;
cmd_info_t              buf_din;
logic                   buf_wr_en;
logic [ADDR_WIDTH-1:0]  buf_addr_r;
// mem Outputs
cmd_info_t              buf_dout;
logic [buf_width:0] buf_mem [2**ADDR_WIDTH-1:0]; // with valid entry 
logic  buf_clr_en , buf_valid_free; 
assign buf_wr_en  = (state==CMD_WRITEBACK && !cam_source) ? 1 : 0 ;  // Store info if cmd is depenedent
assign buf_addr_r = cam_match_addr ;
assign buf_addr_w = cam_nxt_addr   ; 
assign buf_dout   = buf_mem[cam_nxt_addr][ADDR_WIDTH-1:0] ; 
assign buf_clr_en = (state==PROC_FINISH) ? 1 : 0 ; 
assign buf_valid_free = ~buf_mem[cam_nxt_addr][ADDR_WDITH]; 
assign buf_din = next_cmd_info ; 
always_ff (@posedge i_clk or negedge i_rstn) begin  
    if (!i_rstn) begin 

    end else begin 
        if (buf_wr_en) begin 
            buf_mem[buf_addr_w]     = {1'b1, buf_din};
        end
        if (buf_clr_en) begin 
            // clear matched address 
            buf_mem[cam_matched_addr][ADDR_WIDTH]  = 0 ; 
            cam_nxt_addr <= cam_matched_addr; 
        end   
        else begin 
            if (buf_mem[cam_nxt_addr][ADDR_WIDTH]) begin 
                if(cam_nxt_addr == depth_depth-1)  
                    cam_nxt_addr <= 0 ; 
                else 
                    cam_nxt_addr <= cam_nxt_addr + 1; 
            end
        end
    end
end

//assign next_cmd_info = buf_mem[buf_addr_r][ADDR_WDITH-1:0] ;  
assign o_rd_queue = (cam_counter <=`MAX_CMDS && state==CMD_GET)? 1 :0; 
assign o_ack_proc = (state==SEND_ACK || (state == SIMD_LD1 || state == SIMD_LD2 || state == SIMD_INFO)) ? (`PROC_COUNT'b1 << finish_bit_pos): 0; 
assign o_en_proc = (state==SIMD_SELECT && i_busy_proc[selected_proc]==0) ? (`PROC_COUNT'b1 << finish_bit_pos): 0; 


endmodule   

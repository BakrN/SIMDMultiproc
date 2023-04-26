 /* 
    Controller module responsible for fetching instruction enqueued by CPU and processing them into instructions going to the processors . 
    Also responsible for executing commands without any harzard by preserving dependencies. Commands that are not yet ready to be executed will be enqueued in a local fifo with the command info stored in a local buffer. 
    The main module responsible for preserving dependencies and flushing finished commands 
 */
`include "defines.sv"
`include "find_first_set_bit.sv"
`include "fifo.sv"
`include "mem.sv"

module issuer ( 
    i_clk, 
    i_rstn, 
    // fifo ports
    i_cmd ,
    i_empty_queue, 
    o_rd_queue ,  
    // Proc ports
    i_finish_proc, 
    i_busy_proc  , 
    o_en_proc, // enable or validate instr to proc
    o_ack_proc , 
    o_instr   , 
    o_finished_task
) ;  
input i_clk ;
input i_rstn ;
input i_empty_queue; 
input [`PROC_COUNT-1:0] i_busy_proc ; 
input [`PROC_COUNT-1:0] i_finish_proc;  
output logic [`PROC_COUNT-1:0] o_en_proc ; 
output logic [`PROC_COUNT-1:0] o_ack_proc ;  
output instr_t o_instr;
// fifo ports 
input cmd_t i_cmd ; 
output logic o_rd_queue ;
output o_finished_task; 
// State machine 
// cam Parameters
localparam DATA_WIDTH   = $bits(cmd_id_t) + $clog2(`PROC_COUNT)  ;
localparam ADDR_WIDTH   = $clog2(`MAX_CMDS) ; 
localparam CAM_STYLE    = "SRL";
localparam SLICE_WIDTH  = $bits(cmd_id_t)    ; // only 2 slices 
 
// setup simd array  
localparam IDLE        = 4'd0 ;
localparam SIMD_SELECT = 4'd1 ;
localparam SIMD_LD1    = 4'd2 ;
localparam SIMD_LD2    = 4'd3 ;
localparam SIMD_INFO   = 4'd4 ;
localparam SIMD_STORE  = 4'd5 ;
// fetching and processing from queue and checking with scoreboard 
localparam CMD_GET   =     4'd6 ; // get from queue or fifo
localparam CMD_CHECK =     4'd7 ; // check dep with scoreboard
localparam CAM_WRITE =     4'd8; // insert cmd in cam 
localparam CMD_WRITEBACK = 4'd9 ; // (put dependent cmd in fifo) 

// PROC_FINISH

localparam PROC_FINISH = 4'd10 ; // Flush cmd from enq_cmd map 
 
logic [3:0] state ; 
logic cycle_delay; 
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
        cmd_source<= 0 ; 
        cycle_delay <= 0 ; 
    end 
    else begin  
        case (state)  
            IDLE: begin  
                if (cam_setup) begin 
                    state <= IDLE ; 
                end else begin 
                cycle_delay <= 0 ; 
                dep_counter <= dep_count ; 
                if(|i_finish_proc) begin  
                    // flush id  
                    // map_flush <= 1 ; 
                    state <= PROC_FINISH; 
                    finish_bit_pos <= finished_proc; 
                    cmd_source <= 1 ; // check fifo
                    dep_counter <= dep_count; 
                    cam_matched_addr <= cam_match_addr ;
                    cycle_delay <= 1; 
                end
                
                else if (~&i_busy_proc) begin  
                    // pop last cmd from fifo
                    // Priorities: if cmd finishes check fifo for any dependent  cmds
                    if (dep_fifo_empty || dep_counter == 0) begin 
                        cmd_source = 0 ; 
                    end  else if (i_empty_queue && cmd_source) begin 
                        cmd_source =1 ; 
                    end else  begin 
                        state <=  CMD_GET;  
                        dep_counter <= (dep_counter >0 ) ? dep_counter - 1 : dep_counter; 
                        
                    end


                    if (((!dep_fifo_empty && dep_counter>0) && cmd_source) || !i_empty_queue) begin 

                    end
                    
                end  
            end
            end
            PROC_FINISH: begin  // wait for cam entry to be deleted  (cam writes/delets takes a lot of time) 
                if(cycle_delay) begin 
                    cycle_delay <=  0 ; 
                end else begin 
                    if (!cam_write_busy) begin 
                        $display("Flushing command from cam with procid", finish_bit_pos);
                        cam_counter <= cam_counter -1 ; 
                        state <= IDLE;   
                    end 
                end
            end 
            CMD_GET: begin 
                if (cmd_source) begin// fifo
                    $display("Getting command from fifo with id: %d and dep_id: %d, with data: %d", dep_dout.id, dep_dout.dep, buf_dout);
                    current_cmd_id <= dep_dout.id ; 
                    current_dep_id <= dep_dout.dep; 
                    next_cmd_info  <= buf_dout; 
                    dep_store_idx <= dep_dout.entry_idx; 
                end else begin 
                    $display("Getting new command from outside queue with data", i_cmd);
                    {current_cmd_id , current_dep_id ,next_cmd_info} <= i_cmd; 
                    //$display("Input command : %b", i_cmd);
                end
                state <= CMD_CHECK;
                cycle_delay <= 1; 
            end
            CMD_CHECK: begin // cycle to find if there is a match or not 
                // If matched then compare it with selected finish_bit_pos
                if (cycle_delay) begin 
                    cycle_delay <= 0 ; 
                end else begin  
                   
                $display("New command has id: %d , dep_id: %d ", current_cmd_id , current_dep_id); 
                $display("Command opcode: %d , addr0: %d , addr1: %d , writeback: %d , count: %d", next_cmd_info.op, next_cmd_info.addr_0, next_cmd_info.addr_1, next_cmd_info.wr_addr, next_cmd_info.count);
                $display ("Checking for a match for this data: %b . Match: %b , Match_addr: %h", cam_compare_data, cam_match, cam_match_addr) ; 
                cam_matched <= cam_match ; 
                cam_matched_addr <= cam_match_addr ; 
                state <= CAM_WRITE ; 
                selected_proc <= free_proc;
                cycle_delay <= 1 ; 
                end
            end
            CAM_WRITE : begin  // adds new entry to cam if no match (source0) if source is 1 and no match then we overwrite the entry 
                if (cycle_delay) begin 
                    cycle_delay <= 0; 
                end 
                else begin  
                dep_store_idx <= cam_write_addr;

                if (cmd_source) begin  
                    if (cam_matched) begin 
                        state <= CMD_WRITEBACK;  
                        $display ("CMD still needs command to be executed. CMD id: %d , CTE: %d", next_cmd.id , next_cmd.dep) ; 
                    end else  begin 
                        $display ("Dependency of command finished executing. CMD id: %d ", next_cmd.id , next_cmd.dep) ; 

                        
                        state <= SIMD_SELECT; 
                    end 

                end else begin  // first time seeing command
                    if (!cam_write_busy) begin 

                        if(cam_matched) begin 
                            $display("Command will be written back to FIFO (dependency) , CMD id: %d , Waiting on command id: %d", next_cmd.id , next_cmd.dep);
                            state <= CMD_WRITEBACK; 
                        $display ("BUF will be stored at addr: %h", dep_store_idx) ;
                        end else begin
                         //$display("Continuing with SIMD selection, CMD id: %d , DEP id: %d", next_cmd.id , next_cmd.dep); 
                            cam_counter <= cam_counter + 1;  
                            state <= SIMD_SELECT; 
                    end
                            $display ("Wrote this new data: %b to addr %h", cam_write_data,cam_write_addr ) ; 
                    end
                        
                end
            end
            end
            CMD_WRITEBACK: begin // writeback to fifo
                state <= IDLE; 
                //$display ("Writing back to FIFO, CMD id: %d , DEP id: %d", next_cmd.id , next_cmd.dep) ;
            end
            
            SIMD_SELECT: begin  
                //$display ("enable signal %b", o_en_proc ) ; 
                // DELETE BELOW
                if (cmd_source) begin 
                    $display("came from FIFO: Command opcode: %d , addr0: %d , addr1: %d , writeback: %d , count: %d", next_cmd_info.op, next_cmd_info.addr_0, next_cmd_info.addr_1, next_cmd_info.wr_addr, next_cmd_info.count);
                end
                // DELETE ABOVE
                if (i_busy_proc[selected_proc] == 0) begin 

                    state <= SIMD_LD1 ; 
                end
                else begin 
                    $error("Selected proc shouldn't be zero") ; 
                    state <= SIMD_SELECT; 
                end
            end  
            SIMD_LD1: begin  
                state <= SIMD_LD2;  
            end
            SIMD_LD2: begin 
                state <= SIMD_INFO;
            end
            SIMD_INFO: begin 
                state <= SIMD_STORE; 
            end
            SIMD_STORE: begin 
                state <= IDLE;  
            end
            default: 
                state <= IDLE; 
        endcase

    end 
end

/* ------------------- Logic For Instruction Generetation ------------------- */ 

always_comb begin 
    case (state)
        SIMD_LD1: begin
            o_instr.opcode  = INSTR_LD; 
            o_instr.payload = next_cmd_info.addr_0 ; 
        end
        SIMD_LD2: begin 
            o_instr.opcode  = INSTR_LD; 
            o_instr.payload = next_cmd_info.addr_1; 
        end
        SIMD_INFO: begin
            o_instr.opcode = INSTR_INFO;   
            o_instr.payload.info.op = next_cmd_info.op; 
            o_instr.payload.info.count= next_cmd_info.count; 
        end
        SIMD_STORE: begin
            o_instr.opcode  = INSTR_STORE ; 
            o_instr.payload.addr = next_cmd_info.wr_addr; 
        end
        default: begin
            o_instr = 0 ; 
        end
    endcase
end
//assign  o_instr = (state == SIMD_LD1) ? {  INSTR_LD, next_cmd.info.addr_0 } 
//             : ((state == SIMD_LD2) ?    {  INSTR_LD, next_cmd.info.addr_1 }
//             : ((state == SIMD_INFO) ?   {  INSTR_INFO, { next_cmd.info.count, next_cmd.info.op }}
//             : ((state == SIMD_STORE) ?  {INSTR_STORE , next_cmd.info.wr_addr} : 0))) ;  
//
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
logic [$clog2(`MAX_CMDS)-1:0] dep_store_idx;// in buf
logic dep_fifo_full;
logic dep_fifo_empty;
logic [$clog2(FIFO_DEPTH)-1:0] dep_counter, dep_count ;
localparam FIFO_WIDTH = $bits(dep_cmd_t); 
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
assign dep_din   = {current_cmd_id , current_dep_id, dep_store_idx}; 
assign dep_write = (state==CMD_WRITEBACK) ? 1 : 0 ; 
assign dep_read  = (state==CMD_GET && cmd_source) ? 1 : 0 ; 

/* ------------------------- CAM - CMD_ID , PROC_ID ------------------------- */


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
logic cam_match;
logic [1:0]  select_mask ; 
logic cam_setup; // cam finished setting up (don't start unless it is) 
// Cam Assignments 

assign cam_compare_data = (state==CMD_CHECK) ? {next_cmd.dep, {$clog2(`PROC_COUNT){1'b0}}}: ((state==CAM_WRITE)?{next_cmd.id, {$clog2(`PROC_COUNT){1'b0}}} : {{$bits(cmd_id_t){1'b0}}, finished_proc} ); // ! Maybe just don't start with 0 as the initial value for cmd ids or proc ids. but will test this 
// TODO:  After some testing, we need to add a slice selector to the cam. (to choose if our matching algorithm should be based on command only , proc only or both) (very important)
assign cam_write_addr   = ( state==PROC_FINISH||cmd_source) ? cam_matched_addr : cam_nxt_addr;  // ! Should redefine cam_nxt_addr. For now (test) this will be set to cam_counter
assign cam_write_data   = {next_cmd.id , selected_proc} ;
assign cam_write_enable = (((state==CAM_WRITE && (!cmd_source || (!cam_matched && cmd_source)) )||cam_write_delete) && cycle_delay) ? 1 : 0 ;  
assign cam_write_delete = (state==PROC_FINISH && cycle_delay) ? 1 : 0;  
assign select_mask = (state == CMD_CHECK || state==CAM_WRITE)  ? 2'b10 : 2'b01; // * search for proc id when it's finished, otherwise just look at cmd_id 
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
    .select_mask             (select_mask) , 
    .compare_data            ( cam_compare_data   ),
    .write_busy              ( cam_write_busy     ),
    .match_many              ( cam_match_many     ),
    .match_single            ( cam_match_single   ),
    .match_addr              ( cam_match_addr     ),
    .match                   ( cam_match          ), 
    .setup                   ( cam_setup         )
);

// Storing payloads of cmds . Standard MEM 
localparam buf_depth = 2**ADDR_WIDTH;
localparam buf_width = $bits(cmd_info_t);
// mem Inputs 
cmd_info_t              buf_din;
logic                   buf_wr_en;
logic [ADDR_WIDTH-1:0]  buf_addr_r, buf_addr_w , cam_nxt_addr;
// mem Outputs
cmd_info_t              buf_dout;
logic [buf_width-1:0] buf_mem [buf_depth-1:0]; // with valid entry 
logic  buf_clr_en ; 
assign buf_wr_en  = (state==CMD_WRITEBACK && !cmd_source) ? 1 : 0 ;  // Store info if cmd is depenedent
assign buf_addr_r = dep_dout.entry_idx;
assign buf_addr_w = cam_nxt_addr   ; 
assign buf_dout   = buf_mem[buf_addr_r] ; 
assign buf_din =   next_cmd_info ; 
always_ff @(posedge i_clk or negedge i_rstn) begin  
    if (!i_rstn) begin 
    end else begin 
        if (buf_wr_en) begin 
            buf_mem[buf_addr_w] = buf_din;
            $display ("Writing to buf_mem[%d] = %d",buf_addr_w, buf_din);
        end
    end
end
/* --------- Valid Generation of next free cam entry  (cam_nxt_addr) -------- */
logic [`MAX_CMDS-1:0] valid_entries;  
logic fill_entry , del_entry; 
assign del_entry = (state==PROC_FINISH && cycle_delay ) ? 1 : 0 ; 
logic free_entry;   
assign free_entry = ~valid_entries[cam_nxt_addr] ; 
assign fill_entry = (state==CAM_WRITE && cycle_delay) ? 1 : 0 ; 
always_ff @(posedge i_clk or negedge i_rstn)begin  
    if (!i_rstn) begin 
        for (int i = 0 ; i < `MAX_CMDS; i++)begin 
            valid_entries[i] <=0 ; 
        end
    end else begin 
        if (del_entry)begin 
            valid_entries[cam_write_addr] = 0; // free
            cam_nxt_addr<= cam_write_addr;  
        end 
        else if (!free_entry)begin 
            if (cam_nxt_addr == `MAX_CMDS) begin
                cam_nxt_addr <= 0 ; 
            end else begin 
                cam_nxt_addr <= cam_nxt_addr + 1; 
            end
        end
        if(fill_entry) begin 
            valid_entries[cam_write_addr] = 1; // occupied
        end 
        
    end
end
//assign next_cmd_info = buf_mem[buf_addr_r][ADDR_WDITH-1:0] ;  
assign o_rd_queue = (cam_counter <=`MAX_CMDS && state==CMD_GET && !cmd_source)? 1 :0; 
assign o_ack_proc = ( (state == SIMD_LD1 || state == SIMD_LD2 || state == SIMD_INFO || state==SIMD_STORE)) ? (`PROC_COUNT'b1 << selected_proc): ( (state==PROC_FINISH) ? `PROC_COUNT'b1 << finish_bit_pos : 0); 
assign o_en_proc = (state==SIMD_SELECT ) ? (`PROC_COUNT'b1 << selected_proc): 0; 
assign o_finished_task = (state == IDLE && |i_busy_proc==0) ? 1 : 0;

endmodule   

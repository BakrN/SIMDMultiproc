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
    o_cmd , 
    o_finished_task
) ;  
input i_clk ;
input i_rstn ;
input i_empty_queue; 
input [`PROC_COUNT-1:0] i_busy_proc ; 
input [`PROC_COUNT-1:0] i_finish_proc;  
output logic [`PROC_COUNT-1:0] o_en_proc ; 
output cmd_info_t o_cmd ;

// fifo ports 
input cmd_t i_cmd ; 
output logic o_rd_queue ;
output o_finished_task; 
// State machine 
// cam Parameters
//
logic mode ; // recomp/decomp(out of order) or in order (matmul stage) 

localparam DATA_WIDTH   = 8 ; // ($ceil((($bits(cmd_id_t) + $clog2(`PROC_COUNT)) / SLICE_WIDTH)) * SLICE_WIDTH);
localparam ADDR_WIDTH   = $clog2(`MAX_CMDS) ; 
localparam PADDING_SIZE = 2 ;//DATA_WIDTH - ($bits(cmd_id_t) + $clog2(`PROC_COUNT)) ;
localparam CAM_STYLE    = "BRAM";
localparam SLICE_WIDTH  = 4;//$bits(cmd_id_t)    ; // only 2 slices 
 
// setup simd array  
localparam IDLE        = 4'd0 ;
localparam SIMD_SELECT = 4'd1 ;
// fetching and processing from queue and checking with scoreboard 
localparam CMD_GET   =     4'd2 ; // get from queue or fifo
localparam CMD_CHECK =     4'd3 ; // check dep with scoreboard
localparam CAM_WRITE =     4'd4; // insert cmd in cam 
localparam CMD_WRITEBACK = 4'd5 ; // (put dependent cmd in fifo) 

// PROC_FINISH

localparam FIND_PROC   = 4'd6 ; 
localparam PROC_FINISH = 4'd7 ; // Flush cmd from enq_cmd map 

 
logic [3:0] state ; 
logic cycle_delay; 
cmd_t next_cmd;  // next command to execute
cmd_info_t next_cmd_info ; 
cmd_id_t current_cmd_id ,current_dep_id; 
logic cmd_source; // 0: queue , 1:fifo
logic [1:0] proc_finish_delay; 
logic cam_write_en_reg ; 
assign next_cmd = {current_cmd_id, current_dep_id, next_cmd_info}; 
assign o_cmd = next_cmd_info;
// Current state update logic 
always_ff @(posedge i_clk or negedge i_rstn) begin 
    if (!i_rstn) begin 
        state <= IDLE ;  
        cam_counter <= 0 ; 
        cam_nxt_addr <= 0 ;
        cmd_source<= 0 ; 
        cycle_delay <= 0 ; 
        cam_write_en_reg <= 0 ;
        finish_bit_pos <= 0 ;
    end 
    else begin  
        case (state)  
            IDLE: begin  
                if (cam_setup ) begin 
                    state <= IDLE ; 
                end else begin 
                cycle_delay <= 0 ; 
                proc_finish_delay <= 0 ;

                if(|i_finish_proc) begin  
                    // flush id  
                    // map_flush <= 1 ; 
                    state <= FIND_PROC; 
                    finish_bit_pos <= finished_proc; 
                    cmd_source <= 1 ; // check fifo
                    cycle_delay <= 1; 
                end
                
                else if (~&i_busy_proc) begin  
                    // pop last cmd from fifo
                    // Priorities: if cmd finishes check fifo for any dependent  cmds
                    if (dep_fifo_empty ) begin 
                        cmd_source = 0 ; 
                    end  else if (i_empty_queue) begin 
                        cmd_source =1 ; 
                    end

                    if ((((!dep_fifo_empty ) && cmd_source) || !i_empty_queue)&& cam_counter <`MAX_CMDS) begin 
                        state <=  CMD_GET;  
                    end
                    
                end  
            end
            end
            FIND_PROC: begin 
            if (cam_write_busy) begin 
                state <= FIND_PROC ;
            end else begin 
            if (cycle_delay) begin 
                cycle_delay <= 0 ;
            end else begin 
                $display ("PROC_FINISH: Checking for a match for this data: %b . Match: %b , Match_addr: %h", u_enq_cmds.cam_inst.compare_data_padded , cam_match, cam_match_addr) ;  
                if (!cam_match) begin 
                    
                    for (int i = 0 ; i < 2 ; i++) begin 
                        $display ("match many raw _out: %b", u_enq_cmds.cam_inst.match_raw_out[i]);
                    end
                    $display(" TRYING TO DELETE PROC THAT DOESN'T EXIST");
                    $finish; 
                end
                cam_matched_addr <= cam_match_addr ;
                $display ("PROC_FINISH :FOUND MATCH AT %h", cam_match_addr);
                state <= PROC_FINISH; 
                cam_write_en_reg <= 1 ; 
            end
            end
            end
            PROC_FINISH: begin  // wait for cam entry to be deleted  (cam writes/delets takes a lot of time) 
                    if (cam_write_en_reg) begin 
                        cam_write_en_reg <= 0 ; 
                    end else begin 
                        cam_counter <= cam_counter -1 ; 
                        $display ("finished command %b", finish_bit_pos); 
                        state <= IDLE;
                    end


            end 
            CMD_GET: begin 
                if (cmd_source) begin// fifo
                    $display("Getting command from fifo with id: %d and dep_id: %d, with data: %d , and addr : %d", dep_dout.id, dep_dout.dep, buf_dout, dep_dout.entry_idx);
                    current_cmd_id <= dep_dout.id ; 
                    current_dep_id <= dep_dout.dep; 
                    next_cmd_info  <= buf_dout; 
                    dep_store_idx  <= dep_dout.entry_idx; 
                end else begin 
                    //$display("Getting new command from outside queue with data", i_cmd);
                    {current_cmd_id , current_dep_id ,next_cmd_info} <= i_cmd; 
                    //$display("Input command : %b", i_cmd);
                end
                state <= CMD_CHECK;
                cycle_delay <= 1; 
            end
            CMD_CHECK: begin // cycle to find if there is a match or not 
                // If matched then compare it with selected finish_bit_pos
                if (cam_write_busy) begin 
                    state <= CMD_CHECK ; 
                end else begin 
                    if (cycle_delay) begin 
                        cycle_delay <= 0 ; 
                    end else begin  
                   
                $display("New command has id: %d , dep_id: %d ", current_cmd_id , current_dep_id); 
                $display("Command opcode: %d , addr0: %d , addr1: %d , writeback: %d , count: %d", next_cmd_info.op, next_cmd_info.addr_0, next_cmd_info.addr_1, next_cmd_info.wr_addr, next_cmd_info.count);
                //$display ("Checking for a match for this data: %b . Match: %b , Match_addr: %h",u_enq_cmds.cam_inst.compare_data_padded , cam_match, cam_match_addr) ;  
                for (int i = 0 ; i < 2 ; i++) begin 
                    $display ("match many raw _out: %b", u_enq_cmds.cam_inst.match_raw_out[i]);
                end
                cam_matched <= cam_match ; 
                cam_matched_addr <= cam_match_addr ; 


                selected_proc <= free_proc;
                cycle_delay <= 1 ;  
                if (free_entry) begin 
                    cam_free_addr <= cam_nxt_addr; 
                    if (cmd_source && cam_match) begin 
                        state <= CMD_WRITEBACK;  
                        $display ("CMD still needs command to be executed. CMD id: %d , CTE: %d", next_cmd.id , next_cmd.dep) ; 
                    end else begin 
                        cam_write_en_reg <= 1 ;
                        state <= CAM_WRITE ;  
                    end
                end else begin 
                    
                    $display ("No free entry in cam. CMD id: %d , CTE: %d", next_cmd.id , next_cmd.dep) ;

                    //$finish; 
                    state <= CMD_CHECK; 
                end
            end
        end
            end
            CAM_WRITE : begin  // adds new entry to cam if no match (source0) if source is 1 and no match then we overwrite the entry 
                if (cam_write_en_reg) begin 
                    cam_write_en_reg <= 0 ;
                end 
                else begin  
                if (cmd_source) begin  
                    $display ("Dependency of command finished executing. CMD id: %d , written to %d", next_cmd.id , dep_store_idx) ; 
                    // wait for overwrite 
                    //$finish;
                      state <= SIMD_SELECT; 

                end else begin  // first time seeing command
                        if(cam_matched) begin 
                            $display("Command will be written back to FIFO (dependency) , CMD id: %d , Waiting on command id: %d", next_cmd.id , next_cmd.dep);
                            state <= CMD_WRITEBACK; 
                            dep_store_idx <= cam_free_addr;
                        end else begin
                            $display("Continuing with SIMD selection, CMD id: %d , DEP id: %d", next_cmd.id , next_cmd.dep); 
                            state <= SIMD_SELECT; 
                        end
                        cam_counter <= cam_counter + 1;  
                    end
                end
            end
            CMD_WRITEBACK: begin // writeback to fifo
                state <= IDLE; 
                $display ("Writing back to FIFO, CMD id: %d , DEP id: %d", next_cmd.id , next_cmd.dep) ;
            end
            
            SIMD_SELECT: begin  
                $display ("enable signal %b", o_en_proc ) ; 
                // DELETE BELOW
                if (cmd_source) begin 
                    $display("came from FIFO: Command opcode: %d , addr0: %d , addr1: %d , writeback: %d , count: %d", next_cmd_info.op, next_cmd_info.addr_0, next_cmd_info.addr_1, next_cmd_info.wr_addr, next_cmd_info.count);
                end
                // DELETE ABOVE
                if (i_busy_proc[selected_proc] == 0) begin 

                    state <= IDLE; 
                end
                else begin 
                    $error("Selected proc shouldn't be zero") ; 
                    state <= SIMD_SELECT; 
                end
            end  
            default: 
                state <= IDLE; 
        endcase

    end 
end

/* ------------------- Logic For Instruction Generetation ------------------- */ 
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
logic [$clog2(FIFO_DEPTH)-1:0] dep_count ;
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
logic  [ADDR_WIDTH-1:0]     cam_match_addr;
logic cam_match;
logic [1:0]  select_mask ; 
logic cam_setup; // cam finished setting up (don't start unless it is) 
// Cam Assignments 
always_comb begin 

    if($bits(cmd_id_t) > $clog2(`PROC_COUNT)) begin
        cam_compare_data = {next_cmd.dep , {PADDING_SIZE{1'b0}}, finish_bit_pos} ;
        // if there was a match. 
        if (cam_matched) begin 
            // write a proc id that doesn't exist 
            //localparam [3:0] width = `PROC_COUNT; 
            cam_write_data  = {next_cmd.id , 4'b1111} ;
        end else begin 
            cam_write_data   = {next_cmd.id , {PADDING_SIZE{1'b0}},selected_proc} ;
        end
    end else if($clog2(`PROC_COUNT) > $bits(cmd_id_t)) begin 
        cam_compare_data = { {PADDING_SIZE{1'b0}}, next_cmd.dep,finish_bit_pos} ;
        cam_write_data   = {{PADDING_SIZE{1'b0}},next_cmd.id , selected_proc} ;
    end else begin 
        cam_compare_data = {next_cmd.dep, finish_bit_pos} ;
        cam_write_data   = {next_cmd.id , selected_proc} ;
    end

end
//assign cam_compare_data = {next_cmd.dep, finish_bit_pos} ; // ! Maybe just don't start with 0 as the initial value for cmd ids or proc ids. but will test this 
// TODO:  After some testing, we need to add a slice selector to the cam. (to choose if our matching algorithm should be based on command only , proc only or both) (very important)
//assign cam_write_addr   = ( state==PROC_FINISH||cmd_source) ? cam_matched_addr : cam_free_addr;  
assign cam_write_addr   = ( state==PROC_FINISH) ? cam_matched_addr : ((cmd_source) ? dep_store_idx : cam_free_addr);  




//assign cam_write_enable = (((state==CAM_WRITE && (!cmd_source || (!cam_matched && cmd_source)) )&&cycle_delay) || cam_write_en_reg) ? 1 : 0 ;  
assign cam_write_delete = (state==PROC_FINISH ) ? 1 : 0;  

assign select_mask = (state == CMD_CHECK )  ? 2'b10 : 2'b01; // * search for proc id when it's finished, otherwise just look at cmd_id 
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
    .write_delete            ( cam_write_delete),
    .write_enable            ( cam_write_en_reg),
    .select_mask             ( select_mask) , 
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
logic [ADDR_WIDTH-1:0]  buf_addr_r, buf_addr_w , cam_nxt_addr , cam_free_addr;
// mem Outputs
cmd_info_t              buf_dout;
logic [buf_width-1:0] buf_mem [buf_depth-1:0]; // with valid entry 
logic  buf_clr_en ; 
assign buf_wr_en  = (state==CMD_WRITEBACK && !cmd_source) ? 1 : 0 ;  // Store info if cmd is depenedent
assign buf_addr_r = dep_dout.entry_idx;
assign buf_addr_w = cam_free_addr; 
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
assign del_entry = (state==PROC_FINISH && cam_write_en_reg) ? 1 : 0 ; 
logic free_entry;   
assign free_entry = ~valid_entries[cam_nxt_addr] ; 
assign fill_entry = (cam_write_en_reg) ? 1 : 0 ; 
always_ff @(posedge i_clk or negedge i_rstn)begin  
    if (!i_rstn) begin 
        for (int i = 0 ; i < `MAX_CMDS; i++)begin 
            valid_entries[i] <=0 ; 
        end
    end else begin 
        if (del_entry)begin // error here
            valid_entries[cam_write_addr] = 0; // free
            //cam_nxt_addr<= cam_write_addr;  
        end 
        else if(fill_entry) begin 
            valid_entries[cam_write_addr] = 1; // occupied
        end 
        else if (!free_entry)begin 
            if (cam_nxt_addr == `MAX_CMDS) begin
                cam_nxt_addr <= 0 ; 
            end else begin 
                cam_nxt_addr <= cam_nxt_addr + 1; 
            end
        end

        
    end
end
//assign next_cmd_info = buf_mem[buf_addr_r][ADDR_WDITH-1:0] ;  
assign o_rd_queue = (cam_counter <=`MAX_CMDS && state==CMD_GET && !cmd_source)? 1 :0 ; 
assign o_en_proc = (state==SIMD_SELECT ) ? (`PROC_COUNT'b1 << selected_proc): ( (state==PROC_FINISH && cam_write_en_reg) ? `PROC_COUNT'b1 << finish_bit_pos : 0); 
assign o_finished_task = (state == IDLE && |i_busy_proc==0 && cam_counter==0) ? 1 : 0;
//assign o_finished_task = (state == IDLE && |i_busy_proc==0 ) ? 1 : 0;

endmodule   

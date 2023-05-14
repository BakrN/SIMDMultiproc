`include "array.sv" 
`include "defines.sv" 

/* Instruction steps: 
 * Error possibility: Pre fetching beyond an address range ? 
*/  

module proc#(parameter SIMD_WIDTH = `BUS_W/`USIZE) ( 
    i_clk    , 
    i_rstn   , 
    i_en     ,
    i_grant_rd  , 
    i_grant_wr  , 
    i_cmd , 
    i_data , 
    o_addr  , 
    o_finish , 
    o_req_rd, 
    o_req_wr, 
    o_data   ,  
    o_wr_size , 
    o_wr_en , 
    o_busy  
    `ifdef DEBUG 
        , o_state
    `endif
); 
// Inner product multiplication   
//
/* ---------------------------- Local Parameters ---------------------------- */
    // FSM setup 
    localparam IDLE      = 4'd0;  
    localparam LD_CMD    = 4'd1; 
    // FSM process         
    localparam FETCH1    = 4'd2;   // fetch block for addr_0 
    localparam FETCH2    = 4'd3;   // fetch block for addr_1  
    localparam PRE_FETCH = 4'd4;   // pre fetch extra matrix data block
    localparam WRITE     = 4'd5;  
    localparam FINISHED  = 4'd6;  
    localparam MATMUL    = 4'd7;       // MAC cycles happend here 
    localparam NEXT_COL = 4'd8;
    localparam NEXT_ROW = 4'd9;
    localparam SHIFT_REG = 4'd10; 
/* -------------------------------- IO Ports -------------------------------- */
    input  cmd_info_t i_cmd; 
    input i_clk  ;
    input i_rstn ;
    input i_en   ;
    input i_grant_rd ;
    input i_grant_wr ;
    input  logic  [`BUS_W-1:0] i_data  ; // data read from shared mem
    output o_finish;
    output logic o_req_rd;
    output logic o_req_wr;
    output o_busy;
    output addr_t o_addr ; // for accessing shared mem  
    output logic[2:0] o_wr_size;
    output logic [`BUS_W-1:0]  o_data;
    output o_wr_en ;
    `ifdef DEBUG 
        output [3:0] o_state; 
        assign o_state = state;
    `endif


cmd_info_t instr_info ;

/* ---------------------------- Logic Definition ---------------------------- */
// array logci
logic [3:0] state ;   
addr_t addr_0 ;
addr_t addr_1 ; 
addr_t next_addr_0 ; 
addr_t next_addr_1 ; 
addr_t wr_addr ; 
addr_t next_wr_addr; 
cmd_id_t r_id ;  
// SIMD regs  
logic [`BUS_W-1:0] reg0 , reg1 ;  
logic [`BUS_W-1:0] matrix; 

// assigning to instr info 

assign wr_addr = (instr_info.op[1]) ? (instr_info.wr_addr+instr_info.count-(current_row)) : instr_info.wr_addr ;// matmul

// logic for controlling when fsm finishes 
logic [7:0] task_size, next_task_size ; 
// Matmul logic (max 256 matrices) 
logic [7:0] current_row , next_row , current_col , next_col ; 
logic [`BUS_W-1:0] matrix_prefetch_reg;  
addr_t row_addr; // row address
logic [$clog2(SIMD_WIDTH)-1:0] mac_ops_done ;
always_comb begin 
    next_row = current_row + SIMD_WIDTH ;
    next_col = current_col + SIMD_WIDTH ; 
end

//always_comb begin : next_state_block 
//    if (instr_info.op[1])begin 
//        if(next_col >= isntr_info.count) begin  
//            // only write back 
//            if(next_row >= instr_info.count)  begin 
//                next_state <= FINISHED ;
//            end else begin 
//                state <= NEXT_ROW; 
//            end
//            end  
//            else begin 
//            state <= NEXT_COL;
//        end
//    end
//end


logic arr_rstn, arr_en, arr_valid ; 
logic [`USIZE-1:0] arr_res [SIMD_WIDTH];  
logic [SIMD_WIDTH*`USIZE-1:0] arr_res_raw;
logic [`USIZE-1:0] arr_a [SIMD_WIDTH];
logic [`USIZE-1:0] arr_b [SIMD_WIDTH];
always_comb begin 
    for (int i = 0 ; i < SIMD_WIDTH; i ++ )  begin 
        arr_res[i] = arr_res_raw[i*`USIZE +: `USIZE];
    end
end
/* -------------------------- Modules Instantiation ------------------------- */ 
simd_array #(.UNIT_SIZE(`USIZE), .WIDTH(SIMD_WIDTH)) u_arr(
    .i_clk  (i_clk ),  
    .i_rstn (arr_rstn), 
    .i_op   (instr_info.op), 
    .i_a    (arr_a) ,  
    .i_b    (arr_b) ,  
    .i_run (arr_en),  
    .o_valid(arr_valid), 
    .o_res  (arr_res_raw)
);
// Array input logic assignment 
always_comb begin : array_io
    if (instr_info.op[1]) begin 
        // matmul 
        // mac_ops_done 

        for (int i = 0 ; i < SIMD_WIDTH; i++) begin  
            if (mac_ops_done+(SIMD_WIDTH-1-i)>=SIMD_WIDTH) begin 
                // pre fetcher here
                 arr_a[i]= matrix_prefetch_reg[`BUS_W-(mac_ops_done-1-i)*`USIZE-1-:`USIZE];
            end else begin 
                 arr_a[i] = reg0[(i-mac_ops_done)*`USIZE +: `USIZE];   
            end
            arr_b[i] = reg1[(SIMD_WIDTH-mac_ops_done)*`USIZE-1 -: `USIZE]; 
            o_data[i*`USIZE +: `USIZE] = arr_res[SIMD_WIDTH-1-i]; 
        end 


    end
    else begin  
        // elementwise operation
        for (int i = 0 ; i < SIMD_WIDTH; i++) begin 
            arr_a[i] = reg0[i*`USIZE +: `USIZE];
            arr_b[i] = reg1[i*`USIZE +: `USIZE];
            o_data[i*`USIZE +: `USIZE] = arr_res[i];
        end
    end
end




// Next address 
always_comb begin  
    next_addr_0 = addr_0  + SIMD_WIDTH; // index
    next_addr_1 = addr_1  + SIMD_WIDTH; 
    if (instr_info.op[1]) begin  
        // matmul
        if (task_size >= SIMD_WIDTH) begin 
            next_wr_addr = wr_addr - SIMD_WIDTH; 
        end else begin 
            next_wr_addr = wr_addr - task_size;
        end
    end else begin  
        // elementwise operation
        next_wr_addr= wr_addr + SIMD_WIDTH; 
    end

end

/* ---------------------------- FSM Definition ------------------------------- */

    always_ff @(posedge i_clk or negedge i_rstn) begin 
        if (!i_rstn) begin 
            state <= IDLE;  
            current_row <= 0 ;
            current_col <= 0 ; 
            arr_en <= 0 ; 
            arr_rstn <= 0;  
            mac_ops_done <=0 ; 
        end else begin  
            if (!arr_rstn) begin 
                arr_rstn <= 1;
            end
            case (state) 
            // FSM Setup 
            IDLE: begin 
                if (i_en) begin 
                    state <= LD_CMD ; 
                end
            end 
            LD_CMD: begin 
                instr_info <= i_cmd;  
                current_row <= 0 ; 
                current_col <= 0 ; 
                state <= FETCH1 ; 
                task_size <= i_cmd.count;  
                row_addr  <= i_cmd.addr_0;  
                addr_0    <= i_cmd.addr_0;
                addr_1    <= i_cmd.addr_1;  
                
               // $display("DISPLAY CMD: op: %d, count: %d, addr_0: %d, addr_1: %d",i_cmd.op, i_cmd.count, i_cmd.addr_0, i_cmd.addr_1); 
            end
            // FSM Process 
            FETCH1: begin  
                if(i_grant_rd) begin 
                    //$display ("Fetch1 happending. addr0: %d, addr1: %d, op: %d, count: %d, writeback:%d, o_wr_size: %d", addr_0, addr_1, instr_info.op, instr_info.count, o_addr, o_wr_size);
                        addr_0<= next_addr_0;
                        reg0 <= i_data ;  
                        if (instr_info.op[1]) begin 
                            //matmul 
                            state <= PRE_FETCH; 
                        end else begin 
                            state <= FETCH2 ;  
                        end

                end  
                //$display ("[PROC] FETCH1 , i_addr: %d, i_data: %h", addr_0, i_data);
            end
            FETCH2: begin  
                    reg1 <= i_data ; 
                    addr_1 <= next_addr_1; 
                    arr_en <= 1 ; 
                    if (instr_info.op[1] ) begin 
                        //matmul  
                        state <= MATMUL; 
                    end
                    else begin 
                        state <= WRITE; 

                    end


                //$display ("[PROC] FETCH2 , i_addr: %d, i_data: %h", addr_1, i_data);
            end
            PRE_FETCH: begin 
                if (i_grant_rd) begin 
                    addr_0 <= next_addr_0; 
                    matrix_prefetch_reg <= i_data;
                    state <= FETCH2; 
                end
            end
            WRITE: begin 
                // if req granted  
                if(arr_en) begin
                    arr_en <= 0 ; 
                end else begin 
                if (i_grant_wr)   begin 
                    //if (1)begin  // if done write  
                        //$display("[PROC] WRITE, o_addr: %d, o_data: %h , o_wr_size: %d", o_addr, o_data, o_wr_size);
                        if (!instr_info.op[1]) begin // not mat mul 
                            instr_info.wr_addr <= next_wr_addr;
                            if(task_size <= SIMD_WIDTH) begin  // if done with command
                                state <= FINISHED ;  
                            end else  begin 
                                // update count for elementwise ops
                                task_size <= task_size - SIMD_WIDTH; // - SIMD WIDTH 
                                state <= FETCH1;  
                            end
                        end else if(arr_valid) begin 


                            task_size <= next_task_size; 
                            if (next_task_size == 0 ) begin  
                                state <= FINISHED;
                            end else begin 
                                if (current_col == 0 ) begin
                                    // new row
                                    state <= FETCH1 ; 
                                end else begin 
                                    state <= SHIFT_REG; // either finished or SHIFT_REG 
                                end
                            end
                        end
                        arr_rstn <= 0; 
                        
                                            //end 
                end
            end
                //$display ("[PROC] WROTE: %d", o_data);
            end 

            // Matmul FSM 
            // make sure to overwrite the p vectors and not the orignial vec
            // (softwate opt) 
            MATMUL: begin 
                // when done go back to fetch or write 
                // if done check if count size of cols (size of matvec) 
                if (arr_en) begin 
                    arr_en <= 0 ;  
                end else begin 
                    if (arr_valid) begin 
                        if (mac_ops_done==SIMD_WIDTH-1) begin 
                            // finished  
                            mac_ops_done <= 0 ;
                            if (next_col >= instr_info.count) begin 
                                state <= NEXT_ROW ;
                            end else begin 
                                state <= NEXT_COL ; 
                            end

                        end else begin 
                            arr_en <= 1 ; 
                            mac_ops_done <= mac_ops_done + 1 ; 
                            
                        end
                    end 
                end
            end

            NEXT_COL: begin 
                // send MAC rest and set fetching  and go back to write (update current row) 
                // go to overwrite reg0 with prefetch and then go to prefetch  

                state <= SHIFT_REG ;  
                current_col <= next_col ; 

    
            end

            NEXT_ROW: begin 
                // send MAC reset & set fetching (addresses)  (update current col and
                // task size) 
                // go to write,  overwrite reg0 with prefetch and then go to prefetch  
                if (task_size > SIMD_WIDTH)begin 
                    next_task_size <= task_size - SIMD_WIDTH;   
                end else begin 
                    next_task_size = 0 ; 
                end

                current_row <= next_row; 
                current_col <= 0 ; // set next state 
                row_addr <= row_addr + SIMD_WIDTH;
                addr_0   <= row_addr + SIMD_WIDTH ;   
                addr_1   <= instr_info.addr_1;
                state<= WRITE ; 
            end
            FINISHED: begin 
                 // stall here  // wait until I recieve aknowledgement from issuer that scoreboard was flushed 
                 if (i_en) begin 
                    state <= IDLE ; 
                 end
            end 
            // MATMUL FSM END
            SHIFT_REG:begin  
                reg0 <= matrix_prefetch_reg ;
                state <= PRE_FETCH; 
            end
            default: 
                state <= IDLE ;
            endcase 

        end
    end
    /* ---------------------------- Output Assignment ---------------------------- */
    assign o_addr   =  (state==FETCH1 || state==PRE_FETCH)? addr_0: ((state==FETCH2) ? addr_1: wr_addr); 
    assign o_req_rd =  ((state==FETCH1)|| (state==FETCH2) || (state==PRE_FETCH)) ? 1 : 0 ;  
    assign o_req_wr =  (state==WRITE) ? 1 : 0 ; 
    assign o_busy   =  (state==IDLE ) ? 0 : 1 ;  
    assign o_finish =  (state==FINISHED) ? 1 : 0 ; 
    assign o_wr_size=  (task_size <= SIMD_WIDTH ) ? task_size[2:0] : SIMD_WIDTH;  
    assign o_wr_en =   (state==WRITE && i_grant_wr) ? 1 : 0 ;
endmodule 

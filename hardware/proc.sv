`include "array.sv" 
`include "defines.sv" 
/* Instruction steps: 
    IDLE
    Setup:
        LD reg1 addr
        LD reg2 addr 
        SET (info) 
        STORE writeback addr 
    Exec: 
        REQ access 
        Fetch reg1  
        fetch reg2 
        Writeback 
        Writeback -> IDLE if size or count of ops is 0 else go back to reg1 

*/ 
module proc( 
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
/* ---------------------------- Local Parameters ---------------------------- */
    // FSM setup 
    localparam IDLE      = 3'd0;  
    localparam LD_CMD    = 3'd1; 
    // FSM process         
    localparam FETCH1    = 3'd2;  
    localparam FETCH2    = 3'd3;  
    localparam WRITE     = 3'd4;  
    localparam FINISHED  = 3'd5;  
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

// assigning to instr info 

assign addr_0 = instr_info.addr_0 ; 
assign addr_1 = instr_info.addr_1 ; 
assign wr_addr = instr_info.wr_addr ;

// assigning to instr info 



/* -------------------------- Modules Instantiation ------------------------- */ 
array u_simd_arr (
    .i_in1                   ( reg0    ),
    .i_in2                   ( reg1 ),
    .opcode                  ( instr_info.op  ),
    .o_res                   ( o_data ) 
);

// Next address 
always_comb begin 
    next_addr_0 = addr_0  + `BUS_W/`USIZE ; // index
    next_addr_1 = addr_1  + `BUS_W/`USIZE ; 
    next_wr_addr= wr_addr + `BUS_W/`USIZE ; 
end
/* ---------------------------- FSM Definition ------------------------------- */

    always_ff @(posedge i_clk or negedge i_rstn) begin 
        if (!i_rstn) begin 
            state <= IDLE; 
        end else begin  
            case (state) 
            // FSM Setup 
            IDLE: begin 
                if (i_en) begin 
                    state <= LD_CMD ; 
                end
            end 
            LD_CMD: begin 
                instr_info <= i_cmd; 
                state <= FETCH1 ;
            end
            // FSM Process 
            FETCH1: begin 
                if(i_grant_rd) begin 
                    //$display ("Fetch1 happending. addr0: %d, addr1: %d, op: %d, count: %d, writeback:%d, o_wr_size: %d", addr_0, addr_1, instr_info.op, instr_info.count, o_addr, o_wr_size);
                        if (instr_info.op == 2) begin  // if matmul2x2 pad with zeros
                            reg0 <= {{`USIZE{1'b0}}, i_data[`BUS_W-1-:`USIZE] ,i_data[`BUS_W-`USIZE-1-:`USIZE], i_data[`BUS_W-2*`USIZE-1-:`USIZE], {`USIZE{1'b0}}};
                        end else begin
                            reg0 <= i_data ;  
                        end
                        state <= FETCH2 ;  
                end  
                //$display ("[PROC] FETCH1 , i_addr: %d, i_data: %h", addr_0, i_data);
            end
            FETCH2: begin  
                    if (instr_info.op==2)begin 
                        reg1 <= {i_data[`BUS_W-1-:2*`USIZE] , {`USIZE{1'b0}}, {`USIZE{1'b0}}, {`USIZE{1'b0}}} ;
                    end else begin 
                        reg1 <= i_data ;
                    end
                    state <= WRITE;  
                //$display ("[PROC] FETCH2 , i_addr: %d, i_data: %h", addr_1, i_data);
            end
            
            WRITE: begin 
                // if req granted 
                if (i_grant_wr)   begin 
                    //if (1)begin  // if done write
                        instr_info.addr_0 <= next_addr_0; // update addresses 
                        instr_info.addr_1 <= next_addr_1; 
                        instr_info.wr_addr <= next_wr_addr;
                        if(instr_info.count <= 5) begin  // if done with command
                            state <= FINISHED ;  
                        end else  begin 
                            // update count 
                            instr_info.count <= instr_info.count - 5 ; // - SIMD WIDTH 
                            state <= FETCH1;  
                        end
                    //end 
                end
                //$display ("[PROC] WROTE: %d", o_data);
            end
            FINISHED: begin 
                 // stall here  // wait until I recieve aknowledgement from issuer that scoreboard was flushed 
                 if (i_en) begin 
                    state <= IDLE ; 
                 end
                //$display ("[PROC] FINISHED");
                 
            end
            default: 
                state <= IDLE ;
            endcase 

        end
    end


    assign o_addr   =  (state==FETCH1)? addr_0: ((state==FETCH2) ? addr_1: wr_addr); 
    assign o_req_rd =  ((state==FETCH1)|| (state==FETCH2) ) ? 1 : 0 ;  
    assign o_req_wr =  (state==WRITE) ? 1 : 0 ; 
    assign o_busy   =  (state==IDLE ) ? 0 : 1 ;  
    assign o_finish =  (state==FINISHED) ? 1 : 0 ; 
    assign o_wr_size=  (instr_info.count <= 5 ) ? instr_info.count : 5;  
    assign o_wr_en =  (state==WRITE && i_grant_wr) ? 1 : 0 ;
endmodule 

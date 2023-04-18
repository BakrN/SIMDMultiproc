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
    i_valid  ,
    i_instr , 
    i_data , 
    o_addr  , 
    o_finish , 
    o_req_rd, 
    o_req_wr, 
    o_ack    , 
    o_data   ,  
    o_wr_size , 
    o_busy 
); 
/* ---------------------------- Local Parameters ---------------------------- */
    // FSM setup 
    localparam IDLE      = 4'd0;  
    localparam LD1       = 4'd1; 
    localparam LD2       = 4'd2;  
    localparam SET_INFO  = 4'd3 ;
    // FSM process           
    localparam STORE     = 4'd4;  
    localparam FETCH1    = 4'd5;  
    localparam FETCH2    = 4'd6;  
    localparam WRITE     = 4'd7;  
    localparam FINISHED  = 4'd8;  
/* -------------------------------- IO Ports -------------------------------- */
    input  instr_t i_instr; 
    input i_clk  ; 
    input i_rstn ; 
    input i_en   ; 
    input i_grant_rd ; 
    input i_grant_wr ; 
    input i_valid ; // also used for ack in finished stage 
    output o_finish; 
    output logic o_req_rd; 
    output logic o_req_wr; 
    output o_busy; 
    output logic o_ack ; 
    output addr_t o_addr ; // for accessing shared mem  
    output logic[2:0] o_wr_size;  
    input logic [127:0] i_data  ; // data read from shared mem
    output logic [127:0]  o_data; 


/* ---------------------------- Logic Definition ---------------------------- */
// array logci
logic [3:0] state ;   
addr_t addr_0 , addr_1 , next_addr_0 ,next_addr_1  , wr_addr ;   
cmd_id_t r_id ;  
logic [1:0] simd_opcode; // 0 for add , 1 sub , 2mul
// SIMD regs  
logic [127:0] reg0 , reg1 ; 
// INFO storage   
instr_info_t instr_info ; 

/* -------------------------- Modules Instantiation ------------------------- */ 
simd_arr u_simd_arr (
    .i_in1                   ( reg0    ),
    .i_in2                   ( reg1 ),
    .opcode                  ( instr_info.op  ),
    .o_res                   ( o_data ) 
);

// Next address 
always_comb begin 
    next_addr_0 = addr_0 + 128 ;  
    next_addr_1 = addr_1 + 128 ;  
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
                    state <= LD1 ; 
                end
                o_ack <= 0 ; 
            end 
            LD1: begin 
                if (i_instr.opcode == INSTR_LD && i_valid) begin 
                    state <= LD2 ;   
                    addr_0 <= i_instr.payload ;  
                    o_ack <= 1; 
                end
                else  begin 
                    state <= LD1;
                end
            end 
            LD2: begin 
                if (i_instr.opcode == INSTR_LD && i_valid) begin 
                    state <= SET_INFO;   
                    addr_1 <= i_instr.payload ;  
                    o_ack <= 1 ; 
                end
                else begin 
                    o_ack <= 0 ; 
                    state <= LD2;
                end
            end
            SET_INFO: begin 
                if (i_instr.opcode == INSTR_INFO && i_valid) begin  
                    state <= STORE;    
                    instr_info <= i_instr.payload; 
                    o_ack <= 1 ;  
                end
                else begin 
                    o_ack <= 0 ; 
                    state <= SET_INFO;
                end
            end 
            STORE: begin 
                if(i_instr.opcode == INSTR_STORE && i_valid) begin 
                    state <= FETCH1 ; 
                    wr_addr <= i_instr.payload; 
                    o_ack <= 1 ; 
                end else begin 
                    o_ack <= 0 ; 
                    state <= STORE; 
                end
            end
            // FSM Process 
            FETCH1: begin 
                if(i_grant_rd) begin 
                    //if (1) begin  // if done read 
                        reg0 <= i_data ; 
                        state <= FETCH2 ;  
                    //end
                end 
            end
            FETCH2: begin 
                    reg1 <= i_data ; 
                    state <= WRITE;  
            end
            
            WRITE: begin 
                // if req granted 
                if (i_grant_wr)   begin 
                    //if (1)begin  // if done write
                        addr_0 <= next_addr_0; // update addresses 
                        addr_1 <= next_addr_1; 
                        if(instr_info.count <= 4) begin  // if done with command
                            state <= FINISHED ;  
                        end else  begin 
                            // update count 
                            instr_info.count <= instr_info.count - 4 ; // - SIMD WIDTH 
                            state <= FETCH1;  
                        end
                    //end 
                end
            end
            FINISHED: begin 
                 // stall here  // wait until I recieve aknowledgement from issuer that scoreboard was flushed 
                 if (i_valid) begin 
                    state <= IDLE ; 
                 end
                   
                 
            end
            default: 
                state <= IDLE ;
            endcase 

        end
    end


    assign o_addr   =  wr_addr; 
    assign o_req_rd =  ((state==FETCH1)|| (state==FETCH2) ) ? 1 : 0 ;  
    assign o_req_wr =  (state==WRITE) ? 1 : 0 ; 
    assign o_busy   =  (state==IDLE) ? 0 : 1 ;  
    assign o_finish =  (state==FINISHED) ? 1 : 0 ; 
    assign o_wr_size=  (instr_info.count <= 4 ) ? instr_info.count : 4;  

endmodule 

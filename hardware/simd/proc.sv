`include "array.v" 
`include "../defines.sv" 
/* Instruction steps: 
    Setup:
        LD reg1 
        LD reg2 
        SET size , which to overwrite , last_overwrites size (if it's less than 4 then add 0 or mul 1dependending on overwrite) 
    Exec: 
        REQ access 
        Fetch reg1  
        fetch reg2 
        //Exec 
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
    o_finish , 
    o_req_rd, 
    o_req_wr, 
    o_ack    , 
    o_data   , 
    o_busy 
); 
/* ---------------------------- Local Parameters ---------------------------- */
    // FSM setup 
    localparam IDLE      = 4'd0;  
    localparam LD1       = 4'd1; 
    localparam LD2       = 4'd2;  
    localparam SET_COUNT = 4'd3;  // Here set size of operation and contains id of process you're running
    localparam SET_WRITE = 4'd4;  // Setup overwrite address  
    localparam SET_INSTR = 4'd5;  // Setup instruction
    // FSM process           
    localparam FETCH1    = 4'd7;  
    localparam FETCH2    = 4'd8;  
    localparam WRITE     = 4'd9;  
    localparam FINISHED  = 4'd10;  
/* -------------------------------- IO Ports -------------------------------- */
    input  instr_t i_instr; 
    input i_clk ; 
    input i_rstn; 
    input i_en ; 
    input i_grant_rd ; 
    input i_grant_wr ; 
    input i_valid ; // also used for ack in finished stage 
    output id_t o_id ; 
    output o_finish; 
    output logic o_req_rd; 
    output logic o_req_wr; 
    output o_busy; 
    output logic o_ack ; 
    output logic [127:0]  o_data; 


/* ---------------------------- Logic Definition ---------------------------- */
// array logci
logic [3:0] state ;   
addr_t addr_0 , addr_1 , next_addr_0 ,next_addr_1   ;  
id_t r_id ;  
logic [1:0] simd_opcode; // 0 for add , 1 mul , 2 sub
// SIMD regs 
logic [127:0] reg0 , reg1 ;  

/* -------------------------- Modules Instantiation ------------------------- */
simd_arr u_simd_arr (
    .i_in1                   ( reg0    ),
    .i_in2                   ( reg1 ),
    .opcode                  ( simd_opcode ),
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
                    addr_0 <= i_instr.info ;  
                    o_ack <= 1; 
                end
                else  begin 
                    state <= LD1;
                end
            end 
            LD2: begin 
                if (i_instr.opcode == INSTR_LD && i_valid) begin 
                    state <= SET_COUNT;   
                    addr_1 <= i_instr.info ;  
                    o_ack <= 1 ; 
                end
                else begin 
                    o_ack <= 0 ; 
                    state <= LD2;
                end
            end
            SET_COUNT: begin 
                if (i_instr.opcode == INSTR_INFO && i_valid) begin 
                    state <= FETCH1;   
                    // count <= i_instr.info; 
                    o_ack <= 1 ; 
                end
                else begin 
                    o_ack <= 0 ; 
                    state <= SET_COUNT;
                end
            end
           
            // FSM Process 
            FETCH1: begin 
                if(i_grant_rd) begin 
                    if (1) begin  // if done read 
                        reg0 <= 0 ;  // load from mem
                        state <= FETCH2 ;  
                    end
                end
            end
            FETCH2: begin 
                    reg1 <= 0 ;  
                    // when movin on set  req to 0 
            end
           
            WRITE: begin 
                // if req granted 
                if (i_grant_wr)   begin 
                    if (1)begin  // if done write
                        if(1) begin  // if not done with command
                            state <= FETCH1; 
                        end else 
                            state <= FINISHED ; 
                    end
                end
            end
            FINISHED: begin 
                 // stall here 
                 // wait until I recieve aknowledgement from issuer that scoreboard was flushed 
            end
            default: 
                state <= IDLE ;
            endcase 

        end
    end

    assign o_req_rd =  ((state==FETCH1)|| (state==FETCH2) ) ? 1 : 0 ;  
    assign o_req_wr =  (state==WRITE) ? 1 : 0 ; 
    assign o_busy   =  (state==IDLE) ? 0 : 1 ;
    assign o_finish =  (state==FINISHED) ? 1 : 0 ; 
    

endmodule 
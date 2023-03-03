`include "array.v" 
`include "../defines.svh" 

module proc(
    i_clk    , 
    i_rstn   , 
    i_en     ,
    i_grant  , 
    i_valid  ,
    i_instr , 
    o_finish , 
    o_req    , 
    o_ack    , 
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
    localparam FETCH1    = 4'd6;  
    localparam FETCH2    = 4'd7;  
    localparam EXEC      = 4'd8;  
    localparam WRITE     = 4'd9;  
    localparam FINISHED       = 4'd10;  
/* -------------------------------- IO Ports -------------------------------- */
    input  instr_t i_instr; 
    input i_clk ; 
    input i_rstn; 
    input i_en ; 
    input i_grant ; 
    input i_valid ; 
    output id_t o_id ; 
    output o_finish; 
    output o_req; 
    output o_busy; 
    output logic o_ack ; 


/* ---------------------------- Logic Definition ---------------------------- */
// array logci
logic [3:0] r_state ;   
addr_t in1 , in2, count; 
id_t r_id ;  
logic [1:0] simd_opcode; // 0 for add , 1 mul , 2 sub
// SIMD regs 
logic [127:0] r_buf0 , r_buf1 ;  
wire [127:0 ] simd_res ;

/* -------------------------- Modules Instantiation ------------------------- */
simd_arr u_simd_arr (
    .i_in1                   ( r_buf0    ),
    .i_in2                   ( r_buf1 ),
    .opcode                  ( simd_opcode ),
    .o_res                   ( simd_res    ) 
);

/* ---------------------------- FSM Definition ------------------------------- */

    always_ff @(posedge i_clk or negedge i_rstn) begin 
        if (!i_rstn) begin 
            r_state <= IDLE; 
        end else begin  
            case (r_state) 
            // FSM Setup 
            IDLE: begin 
                if (i_en) begin 
                    r_state <= LD1 ; 
                end
                o_ack <= 0 ; 
            end 
            LD1: begin 
                if (i_instr.opcode == INSTR_LD && i_valid) begin 
                    r_state <= LD2 ;   
                    in1 <= i_instr.info ;  
                    o_ack <= 1; 
                end
                else  begin 
                    r_state <= LD1;
                end
            end 
            LD2: begin 
                if (i_instr.opcode == INSTR_LD && i_valid) begin 
                    r_state <= SET_COUNT;   
                    in2 <= i_instr.info ;  
                    o_ack <= 1 ; 
                end
                else begin 
                    o_ack <= 0 ; 
                    r_state <= LD2;
                end
            end
            SET_COUNT: begin 
                if (i_instr.opcode == INSTR_INFO && i_valid) begin 
                    r_state <= FETCH1;   
                    count <= i_instr.info; 
                    o_ack <= 1 ; 
                end
                else begin 
                    o_ack <= 0 ; 
                    r_state <= SET_COUNT;
                end
            end
            // ! s_set_overwrite add this later 
            // FSM Process 
            FETCH1: begin 
                if (i_grant) begin 
                    r_buf0 <= 0 ;  // load from mem
                    r_state <= FETCH2 ; 
                end
            end
            FETCH2: begin 
                if (i_grant) begin 
                    r_buf1 <= 0 ; 
                end 
            end
            EXEC: begin 
                if (1)begin  // if done (load result of comp in reg)

                end
            end
            WRITE: begin 
                if (1)begin  // if done write
                    if(1) begin  // if done with command
                        r_state <= FETCH1; 
                    end else
                        r_state <= FINISHED ; 
                end

            end
            FINISHED: begin
                 // should I wait or include some sort of interrup in issuer
            end
            default: 
                r_state <= IDLE ;
            endcase 

        end
    end

    assign o_req =  ((r_state==FETCH1)|| (r_state==FETCH2) || (r_state==WRITE)) ? 1 : 0 ; 
    assign o_busy = (r_state==IDLE) ? 0 : 1 ;
    assign o_finish = ((r_state==FINISHED)) ? 1 : 0 ; 
  

endmodule 
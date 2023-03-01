`include "defines.svh" 

module simd_fsm( 
    i_clk    , 
    i_rstn   , 
    i_en     ,
    i_grant  , 
    i_valid  ,
    i_cmd    , 
    o_finish , 
    o_req    , 
    o_ack    , 
    o_busy 
) ; 
    localparam op_add      =0; 
    localparam op_sub      =0; 
    localparam op_mul      =0; 
    localparam op_ld_addr  =0; 
    localparam op_set_info =0; 
    input  instr_t i_cmd ; 
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
    // FSM setup 
    localparam s_idle      = 4'd0;  
    localparam s_ld1       = 4'd1; 
    localparam s_ld2       = 4'd2;  
    localparam s_set_count = 4'd3;  
    // FSM process           
    localparam s_fetch1    = 4'd4;  
    localparam s_fetch2    = 4'd5;  
    localparam s_exec      = 4'd6;  
    localparam s_write     = 4'd7;  
    localparam s_out       = 4'd8;  

    logic [3:0] r_state ;   
    addr_t in1 , in2, count; 

    id_t r_id ;  
    logic [1:0] exec; // 0 for add , 1 mul , 2 sub

    // SIMD regs 
    logic [127:0] r_buf0 , r_buf1 ; 
 
    always_ff @(posedge i_clk or negedge i_rstn) begin 
        if (!i_rstn) begin 
            r_state <= s_idle; 
        end else begin  
            case (r_state) 
            // FSM Setup 
            s_idle: begin 
                if (i_en) begin 
                    r_state <= s_ld1 ; 
                end
                o_ack <= 0 ; 
            end 
            s_ld1: begin 
                if (i_cmd.opcode == op_ld_addr && i_valid) begin 
                    r_state <= s_ld2 ;   
                    in1 <= i_cmd.info ;  
                    o_ack <= 1; 
                end
                else  begin 
                    r_state <= s_ld1;
                end
            end 
            s_ld2: begin 
                if (i_cmd.opcode == op_ld_addr && i_valid) begin 
                    r_state <= s_set_count;   
                    in2 <= i_cmd.info ;  
                    o_ack <= 1 ; 
                end
                else begin 
                    o_ack <= 0 ; 
                    r_state <= s_ld2;
                end
            end
            s_set_count: begin 
                if (i_cmd.opcode == op_set_info&& i_valid) begin 
                    r_state <= s_fetch1;   
                    count <= i_cmd.info; 
                    o_ack <= 1 ; 
                end
                else begin 
                    o_ack <= 0 ; 
                    r_state <= s_set_count;
                end
            end
            // ! s_set_overwrite add this later 
            // FSM Process 
            s_fetch1: begin 
                if (i_grant) begin 
                    r_buf0 <= 0 ;  // load from mem
                    r_state <= s_fetch2 ; 
                end
            end
            s_fetch2: begin 
                if (i_grant) begin 
                    r_buf1 <= 0 ; 
                end 
            end
            s_exec: begin 
                if (1)begin  // if done (load result of comp in reg)

                end
            end
            s_write: begin 
                if (1)begin  // if done write
                    if(1) begin  // if done with command
                        r_state <= s_fetch1; 
                    end else
                        r_state <= s_out ; 
                end

            end
            s_out: begin
                 // should I wait or include some sort of interrup in issuer
            end
            default: 
                r_state <= s_idle ;
            endcase 

        end
    end

    assign o_req =  ((r_state==s_fetch1)|| (r_state==s_fetch2) || (r_state==s_write)) ? 1 : 0 ; 
    assign o_busy = (r_state==s_idle) ? 0 : 1 ;
    assign o_finish = ((r_state==s_out)) ? 1 : 0 ; 
 
endmodule 
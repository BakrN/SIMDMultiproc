`include "array.v" // remove later 
module core(
    // Control signals 
    i_clk , 
    i_rstn , 
    i_instr, 
    
    o_idle , 
    o_busy , 
    o_done , 
    // memory access signals 
    
    // cmd handling signals 
    i_en   
    
); 
input i_clk ; 
input i_rstn;
input i_instr ; // instruction received from function execute stack 
input i_en   ; 
output o_idle;
output o_busy;
output o_done;  


/* ---------------------------- Logic Definition ---------------------------- */

reg         [3:0] r_state ;  
wire [(4*32-1):0] simd_in1;
wire [(4*32-1):0] simd_in2;
reg     [1:0]  simd_opcode;
wire  [(4*32-1):0]  simd_res;

/* -------------------------- Modules Instantiation ------------------------- */
simd_arr u_simd_arr (
    .i_in1                   ( simd_in1    ),
    .i_in2                   ( simd_in2    ),
    .opcode                  ( simd_opcode ),
    .o_res                   ( simd_res    )
);
/* ------------------------------ State Machine ----------------------------- */
always_ff @(posedge i_clk or negedge i_rstn) begin 
    if (!i_rstn)  begin 

    end else begin 

    end

end

endmodule 
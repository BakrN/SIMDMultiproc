
module find_first_set_bit#(parameter WIDTH=4)(
    i_in  , 
    o_pos
) ; 
    input [WIDTH-1:0] i_in ; 
    output logic [$clog2(WIDTH)-1:0]  o_pos ; 
    always_comb begin 
        for (int i = 0;  i< WIDTH; i++) begin  
            if (i_in[i]) begin
                o_pos = i;  
            end
        end
    end
endmodule 
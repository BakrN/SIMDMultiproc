module encoder #(
    parameter WIDTH = 8 
) ( 
    i_in, 
    o_enc
)  ; 
    input  logic [WIDTH-1:0] i_in ; 
    output logic  [$clog2(WIDTH)-1:0] o_enc; 
    
    always_comb begin 
        for (integer i = 0 ; i < WIDTH; i++) begin 
            if (i_in[i]) begin 
                o_enc = i ;  
            end
        end 
    end
    
endmodule 
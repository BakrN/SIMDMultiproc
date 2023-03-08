
module multiplexer#(parameter COUNT=4, parameter WIDTH=4)(
    i_signal,  
    i_select, 
    o_sig
) ; 
    input logic [WIDTH-1:0] i_signal [COUNT-1:0];  
    input logic [$clog2(COUNT)-1:0] i_select; 
    output logic [WIDTH-1:0] o_sig; 
    assign o_sig = i_signal[i_select]; 
endmodule 

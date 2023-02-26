module mem #(parameter DEPTH = 4096, SIZE = 32)(
    input i_clk,
    input [DEPTH-1:0] i_addr_w,
    input [SIZE-1:0] i_data_w,
    input i_wr_en,
    input [DEPTH-1:0] i_addr_r,
    output wire  [SIZE-1:0] o_data 
);

reg [SIZE-1:0] mem [DEPTH-1:0];

always @(posedge i_clk) begin
    if (i_wr_en) begin
        mem[i_addr_w] <= i_data_w;
    end
    
end

    assign o_data  = mem[i_addr_r];
endmodule

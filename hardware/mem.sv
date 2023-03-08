module mem #(parameter DEPTH = 4096, SIZE = 32 , FETCH=4)( // Fetch = how many elements of data to fetch at once
    input i_clk,
    input [DEPTH-1:0] i_addr_w,
    input [SIZE-1:0] i_data_w,
    input i_wr_en,
    input [DEPTH-1:0] i_addr_r,
    output wire  [SIZE-1:0] [FETCH-1:0] o_data /// contiguos block of mem
);

reg [SIZE-1:0] mem [DEPTH-1:0];

always @(posedge i_clk) begin
    if (i_wr_en) begin
        mem[i_addr_w] <= i_data_w;
    end
    
end 
    generate
    for (genvar i = FETCH-1 ; i >=0 ; i--) begin
        assign o_data[i]  = mem[i_addr_r + (FETCH-1-i)*SIZE];
    end 
    endgenerate
endmodule

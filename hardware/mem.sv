`include "defines.sv"
module mem #(parameter DEPTH = `MEM_SIZE, SIZE = 32 , BLOCK_SIZE=4, ADDR_SIZE= $bits(addr_t))( // Fetch = how many elements of data to fetch at once
    input i_clk,
    input [ADDR_SIZE-1:0] i_addr_w,
    input [SIZE-1:0] [BLOCK_SIZE-1:0] i_data_w, 
    input [$clog2(BLOCK_SIZE):0] i_wr_size,  // write block size
    input i_wr_en,
    input [ADDR_SIZE-1:0] i_addr_r, 
    output wire  [SIZE-1:0] [BLOCK_SIZE-1:0] o_data /// contiguos block of mem
);

reg [SIZE-1:0] mem [DEPTH-1:0];

always @(posedge i_clk) begin
    if (i_wr_en) begin
        for (integer i = BLOCK_SIZE-1; i >=0; i--)  begin 
            if (i_wr_size > i) begin
                mem[i_addr_w + (BLOCK_SIZE-1-i)*SIZE] <= i_data_w[i];   
            end 
        end
    end
    
end 
    generate
        for (genvar i = BLOCK_SIZE-1 ; i >=0 ; i--) begin
            assign o_data[i]  = mem[i_addr_r + (BLOCK_SIZE-1-i)*SIZE]; 
        end 
    endgenerate
endmodule

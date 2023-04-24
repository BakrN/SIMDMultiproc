`ifndef _MEM_SV_
`define _MEM_SV_
module mem_mod #(parameter DEPTH = 1024, SIZE = 32 , BLOCK_SIZE=5, ADDR_SIZE= 24)( // Fetch = how many elements of data to fetch at once
    input i_clk,
    input [ADDR_SIZE-1:0] i_addr_w,
    input [BLOCK_SIZE-1:0]  [SIZE-1:0] i_data_w, 
    input [$clog2(BLOCK_SIZE)-1:0] i_wr_size,  // write block size
    input i_wr_en,
    input [ADDR_SIZE-1:0] i_addr_r, 
    output logic [BLOCK_SIZE-1:0][SIZE-1:0] o_data /// contiguos block of mem
);

reg [SIZE-1:0] r_mem [DEPTH-1:0];
    //o_data = addr, addr+1, addr+2, addr+3, addr+4
always_ff @(posedge i_clk)  begin 
   for (int i = 0 ; i < BLOCK_SIZE; i++) begin
       if (i_wr_en &&  (i<i_wr_size)) begin 
           r_mem[i_addr_w + i] <= i_data_w[BLOCK_SIZE-1-i];
       end
   end
   if (i_wr_en) begin 
        //$display("i_addr_w = %h,   size = %h", i_addr_w, i_wr_size);
    end
end
always_comb begin 
    for (int i = 0; i < BLOCK_SIZE ; i++) begin
        o_data[i]  = r_mem[i_addr_r + (BLOCK_SIZE-1-i)];
    end 
end
endmodule
`endif

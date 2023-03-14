`include "defines.sv"
`include "shared_mem.sv"

module tb_shared_mem;
    parameter T = 10 ; 
    // shared_mem Parameters
    parameter BUS_SIZE  = 128;
    parameter COUNT = 4; 
   
    // shared_mem Inputs
    logic clk;
    logic rstn;
    logic [COUNT-1:0]    req_rd;
    logic [COUNT-1:0]    req_wr;
    logic [BUS_SIZE-1:0] proc_wr [COUNT-1:0];
    logic [1:0] wr_size [COUNT-1:0];
    addr_t proc_addr [COUNT-1:0]; 

    // shared_mem Outputs
    logic  [COUNT-1:0]   grant_rd; 
    logic  [COUNT-1:0]   grant_wr;
    logic [BUS_SIZE-1:0] proc_rd [COUNT-1:0]; 

    shared_mem #(
        .COUNT (COUNT) ,
        .BUS_SIZE ( BUS_SIZE))
     u_mem (
        .i_clk                                       (        clk            ), 
        .i_rstn                                      (        rstn           ), 
        .i_req_rd                                    (        req_rd         ), 
        .i_req_wr                                    (        req_wr         ), 
        .i_proc_wr                                   (        proc_wr        ), 
        .i_wr_size                                   (        wr_size        ), 
        .i_proc_addr                                 (        proc_addr      ), 
        .o_grant_rd                                  (        grant_rd       ), 
        .o_grant_wr                                  (        grant_wr       ), 
        .o_proc_rd                                   (        proc_rd        )  
    );

    initial begin 
        $dumpfile("sim/mem_tb.vcd");
        $dumpvars(0, u_mem);
    end 
    initial begin 
        forever begin
            clk = 0 ; 
            #(T/2) ; 
            clk = 1 ; 
            #(T/2) ; 
        end
    end
    initial begin 
        rstn = 1; 
    end

    initial begin 
        #T ;  
        rstn = 0; 
        #T ; 
        rstn = 1 ; 

        /* --------------- Test arbitration signals--------------- */
        // test arbitration signals
        //req_rd = 4'hF;   
        //req_wr = 4'd5;   
        //#T;
        //req_rd = 4'd3;  
        //req_wr = 4'd14;   
        //#T;
        //req_rd = 4'd2;   
        //req_wr = 4'd5;   
        //#T ; 
        /* -------------------------- Test READS and WRITES ------------------------- */
        for (integer i = 0 ; i < 4; i++) begin 
            
        end 
        // test writes and do read to check


        $finish ; 
    end

endmodule
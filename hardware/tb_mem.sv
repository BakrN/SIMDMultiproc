`include "defines.sv"
`include "shared_mem.sv"

module tb_shared_mem;
    parameter T = 10 ; 
    // shared_mem Parameters
    parameter BUS_SIZE  = 160;
    parameter COUNT = 4; 
    parameter ADDR_SIZE= 24 ;  
    parameter MEM_SIZE = 20;
    parameter UNIT_SIZE = 32;
    // shared_mem Inputs
    logic clk;
    logic rstn;
    logic [COUNT-1:0]    req_rd;
    logic [COUNT-1:0]    req_wr;
    logic [BUS_SIZE-1:0] proc_wr [COUNT-1:0]; 
    logic [2:0] wr_size [COUNT-1:0];
    addr_t proc_addr [COUNT-1:0]; 

    // shared_mem Outputs
    logic  [COUNT-1:0]   grant_rd; 
    logic  [COUNT-1:0]   grant_wr;
    logic[BUS_SIZE-1:0] proc_rd ;  

    shared_mem #(
        .PORT_COUNT(COUNT) ,
        .BUS_SIZE ( BUS_SIZE), 
        .MEM_SIZE (MEM_SIZE), 
        .UNIT_SIZE(UNIT_SIZE),
        .ADDR_SIZE (ADDR_SIZE) 
        )
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
        $dumpfile("sim/tb_mem.vcd");
        $dumpvars(0, u_mem);
        $dumpvars(1, tb_shared_mem );
    end 
    initial begin 
        forever begin
            clk = 0 ; 
            #(T/2) ; 
            clk = 1 ; 
            #(T/2) ; 
        end
    end
    int sel ;
    initial begin 
        for (int i = 0 ; i < MEM_SIZE; i++) begin 
            u_mem.u_mem.r_mem[i] = i ;
        end
        // display memory 
        for (int i = 0 ; i < MEM_SIZE; i++) begin 
            $display("mem[%d] = %d", i, u_mem.u_mem.r_mem[i]);
        end
        #T ;  
        rstn = 0; 
        #T ; 
        rstn = 1 ; 
        req_rd = 4'h0 ;
        /* --------------- Test arbitration signals--------------- */
        // proc 3 writes 3 to addr 0 with size 3 
        // proc 2 writes 2 to addr 3 with size 4 
        // proc 1 writes 1 to addr 7 with size 5
        // proc 0 writes 0 to addr 12 with size 1
        // setup data and wr size 
        proc_wr[3] = {32'd3,32'd3,32'd3, 64'd0}  ;
        wr_size[3] = 3 ;
        proc_wr[2] = {32'd2,32'd2,32'd2,32'd2,  32'd0}  ;
        wr_size[2] = 4 ;
        proc_wr[1] = {5{32'd1}}  ;
        wr_size[1] = 5 ;
        proc_wr[0] = 0  ;
        wr_size[0] = 1 ;
        proc_addr[3] = 0 ;
        proc_addr[2] = 3 ;
        proc_addr[1] = 7 ;
        proc_addr[0] = 12 ;

        /* -------------------------- Test READS and WRITES ------------------------- */

        // test arbitration signals
        req_wr = 4'hF; // all processor requesting 
        #T ; 
        $display("Grant write signal is %b", grant_wr);
        assert(grant_wr == 4'h1) else $error("Grant write signal is not correct"); 
        req_wr = 4'b1110; // proc 0 done 
        #T ; 
        $display("Grant write signal is %b", grant_wr);
        assert(grant_wr == 4'h2) else $error("Grant write signal is not correct"); 
        req_wr = 4'b1100; // proc 1 done 
        #T ; 
        $display("Grant write signal is %b", grant_wr);
        assert(grant_wr == 4'h4) else $error("Grant write signal is not correct"); 
        req_wr = 4'b1000; // proc 2 done 
        #T ; 
        $display("Grant write signal is %b", grant_wr);
        assert(grant_wr == 4'h8) else $error("Grant write signal is not correct"); 
        req_wr = 4'h0; // proc 3 done 
        #T; 
        $display("Grant write signal is %b", grant_wr);
        assert(grant_wr == 4'h0) else $error("Grant write signal is not correct"); 
        
        for (int i = 0 ; i < MEM_SIZE; i++) begin 
            $display("mem[%d] = %d", i, u_mem.u_mem.r_mem[i]);
        end
        // assert correct data is in correct place 
        req_rd = 4'hF;// all processor requesting
        #T ;
        $display("Grant read signal is %b", grant_rd);
        assert(grant_rd == 4'h1) else $error("Grant read signal is not correct");
        req_rd = 4'b1110; // proc 0 done 
        // verify data
        sel =0  ;
        for (int i = proc_addr[sel] ; i < proc_addr[sel] + wr_size[sel] ; i++) begin 
            assert(proc_rd[BUS_SIZE-i*UNIT_SIZE-1-:UNIT_SIZE] == proc_wr[sel]) else $error("Data is not correct"); 
        end
        for (int i = proc_addr[sel]+wr_size[sel]; i < proc_addr[sel] + 5; i++) begin 
            assert(proc_rd[BUS_SIZE-i*UNIT_SIZE-1-:UNIT_SIZE] == 0) else $error("over wrote date you shouldn't have");  
        end
        #T ; 
        $display("Grant read signal is %b", grant_rd);
        assert(grant_rd == 4'h2) else $error("Grant read signal is not correct");
        req_rd = 4'b1100; // proc 1 done 
        // verify data
        sel =1  ;
        for (int i = proc_addr[sel] ; i < proc_addr[sel] + wr_size[sel] ; i++) begin 
            assert(proc_rd[BUS_SIZE-i*UNIT_SIZE-1-:UNIT_SIZE] == proc_wr[sel]) else $error("Data is not correct"); 
        end
        for (int i = proc_addr[sel]+wr_size[sel]; i < proc_addr[sel] + 5; i++) begin 
            assert(proc_rd[BUS_SIZE-i*UNIT_SIZE-1-:UNIT_SIZE] == 0) else $error("over wrote date you shouldn't have");  
        end
        #T ; 
        $display("Grant read signal is %b", grant_rd);
        assert(grant_rd == 4'h4) else $error("Grant read signal is not correct");
        req_rd = 4'b1000; // proc 1 done 
        // verify data
        sel =2  ;
        for (int i = proc_addr[sel] ; i < proc_addr[sel] + wr_size[sel] ; i++) begin 
            assert(proc_rd[BUS_SIZE-i*UNIT_SIZE-1-:UNIT_SIZE] == proc_wr[sel]) else $error("Data is not correct"); 
        end
        for (int i = proc_addr[sel]+wr_size[sel]; i < proc_addr[sel] + 5; i++) begin 
            assert(proc_rd[BUS_SIZE-i*UNIT_SIZE-1-:UNIT_SIZE] == 0) else $error("over wrote date you shouldn't have");  
        end
        #T; 
        $display("Grant read signal is %b", grant_rd);
        assert(grant_rd == 4'h8) else $error("Grant read signal is not correct");
        req_rd = 4'b0000; // proc 1 done 
        // verify data
        sel =3  ;
        for (int i = proc_addr[sel] ; i < proc_addr[sel] + wr_size[sel] ; i++) begin 
            assert(proc_rd[BUS_SIZE-i*UNIT_SIZE-1-:UNIT_SIZE] == proc_wr[sel]) else $error("Data is not correct"); 
        end
        for (int i = proc_addr[sel]+wr_size[sel]; i < proc_addr[sel] + 5; i++) begin 
            assert(proc_rd[BUS_SIZE-i*UNIT_SIZE-1-:UNIT_SIZE] == 0) else $error("over wrote date you shouldn't have");  
        end
        #T; 



        #(10*T); 
        $finish ; 
    end

endmodule

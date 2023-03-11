`include "./arbitration_algorithm.sv"

module arbiter #(
    N_REQ = 8  // number of requesters
) (
    input  logic             i_clk             , // clock
    input  logic             i_rst_n           , // synchronous reset active low
    // requester signals
    input  logic [N_REQ-1:0] i_req           , // valids/requests from the requesters
    output logic [N_REQ-1:0] o_grant           // readys/grants to the requesters
);

    logic [N_REQ-1:0] last_ready;
    logic [N_REQ-1:0] next_ready;

    arbitration_algorithm #(N_REQ) ar_ag_inst (
        .next_ready   (next_ready),
        .input_valid  (i_req   ),
        .last_ready   (last_ready),
        .current_ready(o_grant   )
    );

    logic should_service_next;
    // check for deassertions
    logic [N_REQ-1:0] mask; 
    assign mask = o_grant & i_req; 
    always @(*) begin 
        if (|mask==0) begin 
            should_service_next <= 1; 
        end
        else begin  
            should_service_next <= 0 ; 
        end
    end
    

    // if current requester has de-asserted, move on to next one
    
   // assign should_service_next = i_ready & (~|(o_grant & i_req));

    // save the last grant so that it may be used by the arbitration algorithm
    always_ff @(posedge i_clk) begin : proc_last_ready
        if(~i_rst_n) begin
            last_ready <= 0;
        end else if(should_service_next) begin
            last_ready <= o_grant;
        end
    end

    // send out the next ready if a new one should be made available
    always_ff @(posedge i_clk) begin : proc_o_grant
        if(!i_rst_n) begin
            o_grant <= 0;
        end else if(should_service_next) begin
            o_grant <= next_ready;
        end
    end

endmodule
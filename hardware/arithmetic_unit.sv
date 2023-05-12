// cycle delay for add/sub/mul 
// 2 cycle delay for MAC
module a_unit #(parameter WIDTH=32) (
    i_clk , 
    i_rstn, 
    i_a   , 
    i_b   , 
    i_op  , // 0: a + b, 1: a-b: 2: MAC
    i_en  , // should only 
    o_res , 
    o_valid 
) ;  
    input i_clk ; 
    input i_en ; 
    input i_rstn; 
    input logic [1:0] i_op ; 
    input  logic [WIDTH-1:0] i_a; 
    input  logic [WIDTH-1:0] i_b; 
    output logic [WIDTH-1:0] o_res ; 
    output logic o_valid ;
    logic [WIDTH-1:0] mul_res; 
    logic [WIDTH-1:0] add_res; 
    logic [WIDTH-1:0] mul_out; 
    logic [WIDTH-1:0] add_out; 
    logic [WIDTH-1:0] adder_a; 
    logic [WIDTH-1:0] adder_b; 
    
    assign mul_out = i_a * i_b ;
    assign add_out = adder_a+ adder_b; 
    logic[1:0]  state ; 
    localparam IDLE = 2'b00;
    localparam MAC = 2'b01;
    localparam OUT  = 2'b10;

    always_comb begin : adder
        case (i_op) 
            2'b00: begin 
                adder_a = i_a; 
                adder_b = i_b ; 
            end
            2'b01: begin 
                adder_a = i_a ; 
                adder_b = ~i_b + 1'b1 ; 
            end
            2'b10: begin 
                adder_a = mul_res; 
                adder_b = add_res; 
            end
            default: begin 
                adder_a = i_a ; 
                adder_b = i_b ; 
            end
        endcase
    end 

    always @(posedge i_clk or negedge i_rstn) begin 
        if (!i_rstn) begin 
            add_res <= 0 ; 
            mul_res <= 0 ;
            state <=IDLE ;  
            o_valid <= 0 ; 
        end else begin 
            case(state) 
            IDLE:  begin 
                if (i_en) begin 
                    o_valid <= 0 ;
                    if (i_op == 2'b10) begin 
                        state <= MAC ; 
                    end else begin 
                        state <= OUT ; 
                        o_valid <= 1; 
                    end
                end
            end
            MAC: begin 
                mul_res <= mul_out ; 
                state <= OUT ;  
                o_valid <= 1; 
            end  
            OUT: begin 
                add_res <= add_out ; 

                state <= IDLE ; 
            end
            default: 
                state <= IDLE ; 
        endcase 
        end
    end 

    assign o_res = (state==OUT)? add_out : add_res;
endmodule 

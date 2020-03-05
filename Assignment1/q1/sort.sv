`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Written by: Kartik Lakhotia
// parametrized sorting module
//////////////////////////////////////////////////////////////////////////////////
module sort # (
    parameter DATA_WIDTH    = 8,
    parameter ARR_WIDTH     = 8 
)
(
    input                           clk,
    input                           rst,
    input       [DATA_WIDTH-1:0]    ip      [ARR_WIDTH-1:0],
    input                           ipValid,
    input                           exRdy,
    output  reg [DATA_WIDTH-1:0]    op      [ARR_WIDTH-1:0],
    output                          rdy,
    output                          valid   
);

function integer log2;
    input [31:0] value;
    begin
        value = value;
        for (log2 = 0; value > 0; log2 = log2 + 1) begin
            value = value >> 1;
        end
    end
endfunction

parameter   NBITS = log2(ARR_WIDTH);
parameter   INIT = 2'b00, SORTING = 2'b01, DONE = 2'b10;


reg         [1:0]               state;
reg         [NBITS-1:0]         cnt; 


wire        [DATA_WIDTH-1:0]    compOut [ARR_WIDTH-1:0];
wire        [DATA_WIDTH-1:0]    compIn  [ARR_WIDTH-1:0];

wire        [DATA_WIDTH-1:0]    maxVal;
wire        [DATA_WIDTH-1:0]    minVal;

assign  minVal  = 0;
assign  maxVal  = '1;

assign  rdy     = (state != SORTING);
assign  valid   = (state==DONE);

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        state   <= INIT;
        cnt     <= 0;
        op[0]   <= 0;
    end
    else begin
        case (state)
            INIT:
            begin
                cnt     <= 0;
                if (ipValid) begin
                    state   <=  SORTING;
                    op[0]   <=  ip[0];
                end
            end
            SORTING:
            begin
                cnt     <= cnt + 1;
                if (!cnt[0])
                    op[0]   <= compOut[0];
                if (cnt==ARR_WIDTH-1)
                    state   <=  DONE;
            end  
            DONE:
            begin
                cnt     <= 0;
                if (exRdy) begin
                    if (ipValid) begin
                        state   <= SORTING;
                        op[0]   <= ip[0];
                    end    
                    else
                        state   <= INIT;
                end
            end
            default:    state   <= INIT;
        endcase
    end
end

assign  compIn[ARR_WIDTH-1]     =   (~cnt[0]) ? op[ARR_WIDTH-1] : maxVal;
genvar i;
generate
    for (i=0; i<ARR_WIDTH-1; i=i+1) begin: ip_gen
        assign compIn[i] = (~cnt[0]) ? op[i] : op[i+1]; 
    end
    for (i=0; i<ARR_WIDTH; i=i+2) begin: comp_gen
        comparator # (
            .WIDTH  (DATA_WIDTH)
        ) comp_inst
        (
            .ip1    (compIn[i]),
            .ip2    (compIn[i+1]),
            .op1    (compOut[i]),
            .op2    (compOut[i+1])
        );
    end
    for (i=1; i<ARR_WIDTH; i=i+1) begin: op_gen
        always @(posedge clk or negedge rst) begin
            if (!rst)
                op[i]   <= 0;
            else begin
                case (state)
                    INIT:
                    begin
                        if (ipValid)
                            op[i]   <= ip[i];
                    end
                    SORTING:
                    begin
                        if (!cnt[0])
                            op[i]   <= compOut[i];
                        else
                            op[i]   <= compOut[i-1];
                    end
                    DONE:
                    begin
                        if (exRdy && ipValid)
                            op[i]   <= ip[i];
                    end
                endcase
            end
        end
    end
endgenerate

endmodule

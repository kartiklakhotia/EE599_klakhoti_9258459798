`timescale 1ns / 1ps

module dff #(
    parameter WIDTH = 1
)
(
    input clk,
    input rst,
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk or negedge rst) begin
        if (!rst)
            q   <= 0;
        else
            q   <= d;
    end
endmodule


//////////////////////////////////////////////////////////////////////////////////
// Written by: Kartik Lakhotia
// parametrized systolic array
//////////////////////////////////////////////////////////////////////////////////
module sysArr # (
    parameter DATA_WIDTH = 8,
    parameter MAT_WIDTH  = 8
)
(
    input           clk,
    input           rst,
    input           [DATA_WIDTH-1:0] ipA [0:MAT_WIDTH-1][0:MAT_WIDTH-1],
    input           [DATA_WIDTH-1:0] ipB [0:MAT_WIDTH-1][0:MAT_WIDTH-1],
    input           start,
    input           ack,
    output          [DATA_WIDTH-1:0] opC [0:MAT_WIDTH-1][0:MAT_WIDTH-1],
    output          rdy,
    output          valid
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

parameter CNT_WIDTH = log2(MAT_WIDTH);
parameter INIT = 2'b00, MULTIPLYING = 2'b01, DONE = 2'b10; 

reg [1:0] state;
reg [CNT_WIDTH-1:0] idx;
wire [MAT_WIDTH-1:0] opDone [0:MAT_WIDTH-1];
wire [MAT_WIDTH-1:0] restart [0:MAT_WIDTH-1];

wire [CNT_WIDTH-1:0] cnt [0:MAT_WIDTH-1];

assign restart[0][0] = start && rdy; 
assign opDone[0][0] = ((state==DONE) || (cnt[0] == MAT_WIDTH));


assign cnt[0] = idx;

genvar i, j;
generate
    for (i=1; i<MAT_WIDTH; i=i+1) begin: doneRowGen
        dff rd_inst (.clk(clk), .rst(rst), .d(opDone[0][i-1]), .q(opDone[0][i])); 
        dff rr_inst (.clk(clk), .rst(rst), .d(restart[0][i-1]), .q(restart[0][i]));
        dff #(CNT_WIDTH) cnt_d (.clk(clk), .rst(rst), .d(cnt[i-1]), .q(cnt[i]));
    end
    for (i=1; i<MAT_WIDTH; i=i+1) begin: doneColGen1
        for (j=0; j<MAT_WIDTH; j=j+1) begin : doneColGen2
            dff cr_inst (.clk(clk), .rst(rst), .d(restart[i-1][j]), .q(restart[i][j]));
            dff cd_inst (.clk(clk), .rst(rst), .d(opDone[i-1][j]), .q(opDone[i][j]));
        end
    end
endgenerate

assign valid = (opDone[MAT_WIDTH-1][MAT_WIDTH-1]) || (state==DONE); 
assign rdy = (state != MULTIPLYING);

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        state   <= INIT;
        idx     <= 0;
    end
    else begin
        case(state)
            INIT:
            begin
                if (start) begin
                    state   <= MULTIPLYING;
                    idx     <= idx + 1;
                end        
                else
                    idx     <= 0;
            end
            MULTIPLYING:
            begin
                if (opDone[MAT_WIDTH-1][MAT_WIDTH-1])
                    state   <= DONE; 
                if (start)
                    idx     <= 1;
                else if (idx < MAT_WIDTH)
                    idx     <= idx + 1;
            end
            DONE:
            begin
                idx <= 0;
                if (start && ack)
                    state   <= MULTIPLYING;
                else if (ack)
                    state   <= INIT;
            end
        endcase
    end
end


wire [MAT_WIDTH:0] ipValid [0:MAT_WIDTH-1];
wire [DATA_WIDTH-1:0] ipSysArrA [0:MAT_WIDTH-1][0:MAT_WIDTH-1];
wire [DATA_WIDTH-1:0] ipSysArrB [0:MAT_WIDTH-1][0:MAT_WIDTH-1];
wire [DATA_WIDTH-1:0] opSysArrA [0:MAT_WIDTH-1][0:MAT_WIDTH-1];
wire [DATA_WIDTH-1:0] opSysArrB [0:MAT_WIDTH-1][0:MAT_WIDTH-1];


assign ipValid[0][0] = ((state==MULTIPLYING) && (cnt[0] < MAT_WIDTH)) || (start);
assign ipSysArrA[0][0] = ipA[0][cnt[0]];
assign ipSysArrB[0][0] = ipB[cnt[0]][0];

generate
    for (i=1; i<MAT_WIDTH; i=i+1) begin : ipValidGen
        dff vldFFInst (.clk(clk), .rst(rst), .d(ipValid[i-1][0]), .q(ipValid[i][0]));
        assign ipSysArrA[i][0] = ipA[i][cnt[i]];
        assign ipSysArrB[0][i] = ipB[cnt[i]][i];
    end
    for (i=0; i<MAT_WIDTH; i=i+1) begin: ipADataRowGen
        for (j=1; j<MAT_WIDTH; j=j+1) begin: ipADataColGen
            assign ipSysArrA[i][j] = opSysArrA[i][j-1];
        end
    end
    for (i=1; i<MAT_WIDTH; i=i+1) begin: ipBDataRowGen
        for (j=0; j<MAT_WIDTH; j=j+1) begin: ipBDataColGen
            assign ipSysArrB[i][j] = opSysArrB[i-1][j];
        end
    end

    
    for (i=0; i<MAT_WIDTH; i=i+1) begin : peGenRow
        for (j=0; j<MAT_WIDTH; j=j+1) begin: peGenCol
            pe # (DATA_WIDTH) 
            peInst (
                .clk(clk),
                .rst(rst),
                .ipA(ipSysArrA[i][j]),
                .ipB(ipSysArrB[i][j]),
                .ipValid(ipValid[i][j]),
                .restart(restart[i][j]),
                .outA(opSysArrA[i][j]),
                .outB(opSysArrB[i][j]),
                .outC(opC[i][j]),
                .valid(ipValid[i][j+1])
            );
        end
    end
endgenerate

endmodule



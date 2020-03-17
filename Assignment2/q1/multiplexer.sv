`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Written by: Kartik Lakhotia
// parametrized multiplexing layer in the network
//////////////////////////////////////////////////////////////////////////////////
module multiplexer # (
    parameter ELEMS = 16,
    parameter WIDTH = 8
)
(
    input                           clk,
    input                           rst,
    input           [WIDTH-1:0]     ip1     [0:ELEMS-1],
    input           [WIDTH-1:0]     ip2     [0:ELEMS-1],
    input                           sel,
    input                           start,
    input                           ack,
    output reg      [WIDTH-1:0]     op      [0:ELEMS-1],
    output                          rdy,
    output reg                      valid
);


assign rdy = (!valid) || ack;

always @(posedge clk or negedge rst) begin
    if (~rst) begin
        valid       <= 0;
    end
    else begin
        if (rdy && start) begin
            valid       <= 1;
        end
        else if (ack) begin
            valid       <= 0;
        end
    end
end


genvar i;
generate
for (i=0; i<ELEMS; i=i+1) begin
always @(posedge clk or negedge rst) begin
    if (~rst) begin
        op[i]          <= 0;
    end
    else begin
        if (rdy && start) begin
            op[i]          <= (sel) ? ip2[i] : ip1[i];
        end
        else if (ack) begin
        end
    end
end
end
endgenerate


endmodule

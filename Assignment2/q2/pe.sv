`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Written by: Kartik Lakhotia
// parametrized MAC layer in systolic array
//////////////////////////////////////////////////////////////////////////////////
module pe #(
    parameter WIDTH = 8
)
(
    input                           clk,
    input                           rst,
    input           [WIDTH-1:0]     ipA,
    input           [WIDTH-1:0]     ipB,
    input                           ipValid,
    input                           restart, 
    output reg      [WIDTH-1:0]     outA,
    output reg      [WIDTH-1:0]     outB,
    output reg      [WIDTH-1:0]     outC,
    output reg                      valid
);



always @(posedge clk or negedge rst) begin
    if (~rst) begin
        outC        <= 0;
        outA        <= 0;
        outB        <= 0;
        valid       <= 0;
    end
    else begin
        if (ipValid) begin
            outA        <= ipA;
            outB        <= ipB;
            outC        <= ((restart) ? 0 : outC) + ipA*ipB;
            valid       <= 1;
        end
        else
            valid       <= 0;
    end
end


endmodule

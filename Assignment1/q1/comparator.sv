`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Written by: Kartik Lakhotia
// parametrized comparator
//////////////////////////////////////////////////////////////////////////////////
module comparator # (
	parameter WIDTH = 8
)
(
	input			[WIDTH-1:0]	    ip1,
	input			[WIDTH-1:0]     ip2,
	output     	    [WIDTH-1:0]	    op1,
	output          [WIDTH-1:0]     op2
);

wire    switch;

assign  switch  = (ip1 > ip2);
assign  op1     = (switch) ? ip2 : ip1;
assign  op2     = (switch) ? ip1 : ip2;


endmodule

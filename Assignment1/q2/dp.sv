`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Written by: Kartik Lakhotia
// parametrized dot product computation
//////////////////////////////////////////////////////////////////////////////////
module dp # (
	parameter DATA_WIDTH = 8,
	//assume DP_WIDTH is a power of 2 and greater than 1
	parameter DP_WIDTH = 8
)
(
	input                              clk,
	input                              rst,
	input			[DATA_WIDTH-1:0]   ip1    [DP_WIDTH-1:0],
	input			[DATA_WIDTH-1:0]   ip2	   [DP_WIDTH-1:0],
	input                              start,
	input                              ack,
	output 		    [DATA_WIDTH-1:0]   op,
	output                             rdy,
	output                             valid
);

function integer log2;
    input [31:0] value;
    begin
        value = value - 1;
        for (log2 = 0; value > 0; log2 = log2 + 1) begin
            value = value >> 1;
        end
    end
endfunction

parameter TREE_HEIGHT = log2(DP_WIDTH) + 1;


wire	[DATA_WIDTH-1:0]		lvlOut	  [TREE_HEIGHT-1:0][DP_WIDTH-1:0];
wire	[DP_WIDTH-1:0]			lvlRdy    [TREE_HEIGHT:0];
wire	[DP_WIDTH-1:0]			lvlValid  [TREE_HEIGHT-1:0];

assign op							=	lvlOut[TREE_HEIGHT-1][0];
assign rdy							=	lvlRdy[0][0];
assign valid						=	lvlValid[TREE_HEIGHT-1][0];

assign lvlRdy[TREE_HEIGHT][0]	=	ack;

genvar i;
generate
	for (i=0; i<DP_WIDTH; i=i+1) begin : mult_gen
		multiplier # (
			.WIDTH 	(DATA_WIDTH)
		)mult_inst 
		(
			.clk		(clk),
			.rst		(rst),
			.ip1		(ip1[i]),
			.ip2		(ip2[i]),
			.start	    (start),
			.ack		(lvlRdy[1][(i/2)]),
			.op		    (lvlOut[0][i]),
			.rdy		(lvlRdy[0][i]),
			.valid	    (lvlValid[0][i])
		);
	end
endgenerate

genvar lvl;
generate
	for (lvl=1; lvl<TREE_HEIGHT; lvl=lvl+1) begin : tree_gen
		for (i=0; i<(2**(TREE_HEIGHT-lvl-1)); i=i+1) begin : node_gen
			adder # (
				.WIDTH	(DATA_WIDTH)
			)add_inst 
			(
				.clk		(clk),
				.rst		(rst),
				.ip1		(lvlOut[lvl-1][2*i]),
				.ip2		(lvlOut[lvl-1][2*i+1]),
				.start	    (lvlValid[lvl-1][2*i]),
				.ack		(lvlRdy[lvl+1][i/2]),
				.op		    (lvlOut[lvl][i]),
				.rdy		(lvlRdy[lvl][i]),
				.valid	    (lvlValid[lvl][i])
			); 
		end
	end
endgenerate


endmodule

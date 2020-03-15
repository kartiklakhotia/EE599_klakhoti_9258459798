`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Written by: Kartik Lakhotia
// parametrized dot product computation
//////////////////////////////////////////////////////////////////////////////////
module barrel # (
    parameter NUM_ELEMS = 64,
	parameter DATA_WIDTH = 8,
    parameter ROT_WIDTH = $clog2(NUM_ELEMS)
)
(
	input                              clk,
	input                              rst,
	input			[DATA_WIDTH-1:0]   ip1     [0:NUM_ELEMS-1],
    input           [ROT_WIDTH-1:0]    rot,
	input                              start,
	input                              ack,
	output 		    [DATA_WIDTH-1:0]   op      [0:NUM_ELEMS-1],
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

parameter NUM_LAYERS = log2(NUM_ELEMS);


wire	[DATA_WIDTH-1:0]		lvlOut	  [0:NUM_LAYERS-1][0:NUM_ELEMS-1];
wire	[DATA_WIDTH-1:0]		lvlIn1	  [0:NUM_LAYERS-1][0:NUM_ELEMS-1];
wire	[DATA_WIDTH-1:0]		lvlIn2	  [0:NUM_LAYERS-1][0:NUM_ELEMS-1];
wire	[NUM_LAYERS-1:0]		lvlRdy    ;
wire	[NUM_LAYERS-1:0]		lvlStart  ;
wire	[NUM_LAYERS-1:0]		lvlAck    ;
wire	[NUM_LAYERS-1:0]		lvlValid  ;



assign op							=	lvlOut[NUM_LAYERS-1];
assign rdy							=	lvlRdy[0];
assign valid						=	lvlValid[NUM_LAYERS-1];
assign lvlIn1[0]                    =   ip1;
assign lvlAck[NUM_LAYERS-1]         =   ack;
assign lvlStart[0]                  =   start;

genvar i, j;
generate
    for (i=1; i<NUM_LAYERS; i=i+1) begin: ip1_gen
        assign lvlIn1[i] = lvlOut[i-1];
        assign lvlStart[i] = lvlValid[i-1];
    end

    for (i=0; i<NUM_LAYERS-1; i=i+1) begin: ack_gen
        assign lvlAck[i] = lvlRdy[i+1];
    end

    for (i=0; i<NUM_LAYERS; i=i+1) begin: ip2_gen
        for (j=0; j<NUM_ELEMS; j=j+1) begin : ip2_rot_gen
            assign lvlIn2[i][j] = lvlIn1[i][(NUM_ELEMS + j-(2**i))%NUM_ELEMS];
        end
    end

	for (i=0; i<NUM_LAYERS; i=i+1) begin : mult_gen
		multiplexer # (
            .ELEMS  (NUM_ELEMS),
			.WIDTH 	(DATA_WIDTH)
		)mult_inst 
		(
			.clk		(clk),
			.rst		(rst),
			.ip1		(lvlIn1[i]),
			.ip2		(lvlIn2[i]),
            .sel        (selD[i][i]),
			.start	    (lvlStart[i]),
			.ack		(lvlAck[i]),
			.op		    (lvlOut[i]),
			.rdy		(lvlRdy[i]),
			.valid	    (lvlValid[i])
		);
	end
endgenerate

reg     [ROT_WIDTH-1:0]        selD [0:NUM_LAYERS-1];
always @(*) begin
    selD[0] = rot;
end
generate
    for (i=1; i<NUM_LAYERS; i=i+1) begin: selGen
        always@(posedge clk or negedge rst) begin
            if (!rst) 
                selD[i] <= 0;
            else if (lvlStart[i])
                selD[i] <= selD[i-1];
        end
    end
endgenerate

endmodule

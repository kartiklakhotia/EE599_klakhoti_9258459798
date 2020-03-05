`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Written by: Kartik Lakhotia
// parametrized adder
//////////////////////////////////////////////////////////////////////////////////
module adder # (
	parameter WIDTH = 8
)
(
	input							clk,
	input							rst,
	input			[WIDTH-1:0]	    ip1,
	input			[WIDTH-1:0]     ip2,
	input							start,
	input							ack,
	output reg	    [WIDTH-1:0]	    op,
	output 						    rdy,
	output reg					    valid
);


assign rdy = (!valid) || ack;

always @(posedge clk or negedge rst) begin
	if (~rst) begin
		op			<= 0;
		valid		<= 0;
	end
	else begin
		if (rdy && start) begin
			op			<= ip1+ip2;
			valid		<= 1;
		end
		else if (ack) begin
			valid		<= 0;
		end
	end
end


endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Written by: Kartik Lakhotia
// testebench for parametrized dot product computer
//////////////////////////////////////////////////////////////////////////////////


module barrel_tb;

parameter DATA_WIDTH = 8;
parameter NUM_ELEMS = 32;

function integer log2;
    input [31:0] value;
    begin
        value = value - 1;
        for (log2 = 0; value > 0; log2 = log2 + 1) begin
            value = value >> 1;
        end
    end
endfunction

parameter SEL_WIDTH = log2(NUM_ELEMS);

reg clk, rst;

reg [DATA_WIDTH-1:0] ip [NUM_ELEMS-1:0];
reg [DATA_WIDTH-1:0] op [NUM_ELEMS-1:0];
reg [SEL_WIDTH-1:0]  sel;

reg dataValid;
reg tbRdy;

reg [DATA_WIDTH-1:0] opReg [NUM_ELEMS-1:0];

wire dpRdy;
wire opValid;

integer i,j;

initial begin
    clk = 0;
    forever begin
        #5;
        clk = ~clk;
    end
end

event reset_done_trig;
initial begin
    rst = 1;
    @(negedge clk);
    rst = 0;
    #50;
    rst = 1;
    -> reset_done_trig;
end


event comp_start;
event sim_terminate;
initial begin
    for (i=0; i<NUM_ELEMS; i=i+1) begin
        ip[i]  = i;
    end
    @(reset_done_trig);
    @(negedge clk);
    dataValid = 1;
    sel = 11;
    while(!dpRdy)
        @(negedge clk);
    -> comp_start;
    @(negedge clk);
    dataValid = 0;
end

initial begin
    tbRdy = 0;
    @(reset_done_trig);
    @(comp_start);
    tbRdy = 1;
    while(!opValid)
        @(negedge clk);
    @(negedge clk);
    tbRdy = 0;
    -> sim_terminate;

end

initial begin
    @(sim_terminate);
    #10 $finish;
end


always @(posedge clk) begin
        if (tbRdy && opValid) begin
            opReg <= op;
        end
end

barrel #(
    .NUM_ELEMS      (NUM_ELEMS),
    .DATA_WIDTH     (DATA_WIDTH),
    .ROT_WIDTH      (SEL_WIDTH)
) DUT 
(
    .clk        (clk),
    .rst        (rst),
    .ip1        (ip),
    .rot        (sel),
    .start      (dataValid),
    .ack        (tbRdy),
    .op         (op),
    .rdy        (dpRdy),
    .valid      (opValid)
);



endmodule

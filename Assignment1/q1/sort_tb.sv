`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
// Written by: Kartik Lakhotia
// testbench for sorting module
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////


module sort_tb;

parameter DATA_WIDTH = 8;
parameter ARR_WIDTH = 8;

reg clk, rst;
reg [DATA_WIDTH-1:0] arr [ARR_WIDTH-1:0];

reg dataValid;
reg tbRdy;

wire [DATA_WIDTH-1:0] op [ARR_WIDTH-1:0];
reg [DATA_WIDTH-1:0] opReg [ARR_WIDTH-1:0];

wire sorterRdy;
wire opValid;

integer i;

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

event sort_trig;
event sim_terminate;
initial begin
    tbRdy = 0;
    for (i=0; i<ARR_WIDTH; i=i+1) begin
        arr[i] = ARR_WIDTH - i;
    end
    @(reset_done_trig);
    @(negedge clk);
    while(!sorterRdy)
        @(negedge clk);
    dataValid = 1;
    @(posedge clk);
    @(negedge clk);
    dataValid = 0;
    tbRdy = 1;
    -> sort_trig;
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

genvar j;
generate
    for (j=0; j<ARR_WIDTH; j=j+1) begin
        always @(negedge rst or posedge clk) begin
            if (!rst) begin
                opReg[j]    <= 0;
            end
            else begin
                if (tbRdy && opValid) begin
                    opReg[j]    <= op[j]; 
                end
            end
        end
    end
endgenerate

sort #(
    .DATA_WIDTH     (DATA_WIDTH),
    .ARR_WIDTH      (ARR_WIDTH)
) DUT 
(
    .clk        (clk),
    .rst        (rst),
    .ip         (arr),
    .ipValid    (dataValid),
    .exRdy      (tbRdy),
    .op         (op),
    .rdy        (sorterRdy),
    .valid      (opValid)
);
        

endmodule

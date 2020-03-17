`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Written by: Kartik Lakhotia
// testebench for parametrized dot product computer
//////////////////////////////////////////////////////////////////////////////////


module dp_tb;

parameter DATA_WIDTH = 8;
parameter MAT_WIDTH = 4;

function integer log2;
    input [31:0] value;
    begin
        value = value - 1;
        for (log2 = 0; value > 0; log2 = log2 + 1) begin
            value = value >> 1;
        end
    end
endfunction

parameter PTR_WIDTH = log2(MAT_WIDTH);

reg clk, rst;

reg [DATA_WIDTH-1:0] imat1 [0:MAT_WIDTH-1][0:MAT_WIDTH-1];
reg [DATA_WIDTH-1:0] imat2 [0:MAT_WIDTH-1][0:MAT_WIDTH-1];
reg [DATA_WIDTH-1:0] omat [0:MAT_WIDTH-1][0:MAT_WIDTH-1];


reg start;
reg tbRdy;

wire [DATA_WIDTH-1:0] op [0:MAT_WIDTH-1][0:MAT_WIDTH-1];

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
    for (i=0; i<MAT_WIDTH; i=i+1) begin
        for (j=0; j<MAT_WIDTH; j=j+1) begin
            imat1[i][j] = i+j;
            imat2[i][j] = i+j;
        end
    end
    @(reset_done_trig);
    @(negedge clk);
    while(!dpRdy)
        @(negedge clk);
    -> comp_start;
    start = 1;
    @(dpRdy==1);
    @(negedge clk);
    start = 0;
    @(negedge clk);
    while(!opValid)
        @(negedge clk);
end

initial begin
    tbRdy = 0;
    @(reset_done_trig);
    @(comp_start);
    tbRdy = 1;
    @(opValid==1);
    @(negedge clk);
    @(negedge clk);
    tbRdy = 0;
    -> sim_terminate;

end

initial begin
    @(sim_terminate);
    #10 $finish;
end

genvar p, q;
generate
    for (p=0; p<MAT_WIDTH; p=p+1) begin
        for (q=0; q<MAT_WIDTH; q=q+1) begin
            always @(negedge rst or posedge clk) begin
                if (!rst) begin
                    omat[p][q] <= 0;
                end
                else begin
                    if (tbRdy && opValid) begin
                        omat[p][q] <= op[p][q];
                end
            end
        end
    end
end
endgenerate

sysArr #(
    .DATA_WIDTH     (DATA_WIDTH),
    .MAT_WIDTH      (MAT_WIDTH)
) DUT 
(
    .clk        (clk),
    .rst        (rst),
    .ipA        (imat1),
    .ipB        (imat2),
    .start      (start),
    .ack        (tbRdy),
    .opC        (op),
    .rdy        (dpRdy),
    .valid      (opValid)
);



endmodule

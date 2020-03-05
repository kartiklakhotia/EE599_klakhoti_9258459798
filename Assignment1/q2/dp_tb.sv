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

reg [DATA_WIDTH-1:0] imat1 [MAT_WIDTH-1:0][MAT_WIDTH-1:0];
reg [DATA_WIDTH-1:0] imat2 [MAT_WIDTH-1:0][MAT_WIDTH-1:0];
reg [DATA_WIDTH-1:0] omat [MAT_WIDTH-1:0][MAT_WIDTH-1:0];


reg [PTR_WIDTH-1:0] ipRow;
reg [PTR_WIDTH-1:0] ipCol;
reg [PTR_WIDTH-1:0] opRow;
reg [PTR_WIDTH-1:0] opCol;


wire [DATA_WIDTH-1:0] arr1 [MAT_WIDTH-1:0];
wire [DATA_WIDTH-1:0] arr2 [MAT_WIDTH-1:0];

genvar p, q;
generate
    for (p=0; p<MAT_WIDTH; p=p+1) begin: ipGen
        assign arr1[p] = imat1[ipRow][p];
        assign arr2[p] = imat2[p][ipCol];
    end
endgenerate

reg dataValid;
reg tbRdy;

wire [DATA_WIDTH-1:0] op;
reg [DATA_WIDTH-1:0] opReg;

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

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        ipRow <= 0;
        ipCol <= 0;
    end else begin
        if (dataValid && dpRdy) begin
            ipCol <= ipCol + 1;
            if (ipCol == MAT_WIDTH-1)
                ipRow <= ipRow + 1;
        end
    end
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        opRow <= 0;
        opCol <= 0;
    end else begin
        if (opValid && tbRdy) begin
            opCol <= opCol + 1;
            if (opCol == MAT_WIDTH-1)
                opRow <= opRow + 1;
        end
    end
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
    dataValid = 1;
    -> comp_start;
    @((ipCol==MAT_WIDTH-1) && (ipRow==MAT_WIDTH-1) && (dpRdy));
    @(negedge clk);
    @(negedge clk);
    dataValid = 0;
    while(!opValid)
        @(negedge clk);
    @(negedge clk);
end

initial begin
    tbRdy = 0;
    @(reset_done_trig);
    @(comp_start);
    tbRdy = 1;
    @((opRow==MAT_WIDTH-1) && (opCol==MAT_WIDTH-1) && (opValid));
    @(negedge clk);
    @(negedge clk);
    tbRdy = 0;
    -> sim_terminate;

end

initial begin
    @(sim_terminate);
    #10 $finish;
end


always @(negedge rst or posedge clk) begin
    if (!rst) begin
    end
    else begin
        if (tbRdy && opValid) begin
            omat[opRow][opCol]   <= op;
        end
    end
end

dp #(
    .DATA_WIDTH     (DATA_WIDTH),
    .DP_WIDTH      (MAT_WIDTH)
) DUT 
(
    .clk        (clk),
    .rst        (rst),
    .ip1        (arr1),
    .ip2        (arr2),
    .start      (dataValid),
    .ack        (tbRdy),
    .op         (op),
    .rdy        (dpRdy),
    .valid      (opValid)
);



endmodule

`timescale 1ns/1ps

module tb_fir6;

    reg        clk;
    reg        rst;
    reg [7:0]  x_in;
    wire [7:0] y_out;

    // debug wires
    wire [7:0] x0, x1, x2, x3, x4, x5;
    wire [11:0] sum_dbg;

    // DUT
    fir6 dut (
        .clk(clk),
        .rst(rst),
        .x_in(x_in),
        .y_out(y_out),
        .x0(x0), .x1(x1), .x2(x2), .x3(x3), .x4(x4), .x5(x5),
        .sum_dbg(sum_dbg)
    );

    // Clock: 10ns period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Wave dump
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_fir6);
    end

    // Stimulus
    integer i;
    reg [7:0] vec [0:15];

    initial begin
        vec[0]=8'd10;   vec[1]=8'd20;   vec[2]=8'd30;   vec[3]=8'd40;
        vec[4]=8'd50;   vec[5]=8'd60;   vec[6]=8'd70;   vec[7]=8'd80;
        vec[8]=8'd90;   vec[9]=8'd100;  vec[10]=8'd110; vec[11]=8'd120;
        vec[12]=8'd130; vec[13]=8'd140; vec[14]=8'd150; vec[15]=8'd160;

        rst  = 1'b1;
        x_in = 8'd0;

        // reset for 2 cycles
        @(posedge clk);
        @(posedge clk);
        rst = 1'b0;

        // apply inputs
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            x_in <= vec[i];
        end

        // extra cycles
        repeat (6) @(posedge clk);

        $finish;
    end

    // Console print
    initial begin
        $display(" time  rst  x_in | x0 x1 x2 x3 x4 x5 | sum   y_out");
        $monitor("%4t   %b   %3d | %3d %3d %3d %3d %3d %3d | %4d  %3d",
                 $time, rst, x_in, x0,x1,x2,x3,x4,x5, sum_dbg, y_out);
    end

endmodule

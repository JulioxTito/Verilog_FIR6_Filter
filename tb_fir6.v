// =========================================================================
// Testbench: tb_fir6
// Description: Automated Self-Checking Verification Testbench for FIR6 Filter
// Target: Aldec Riviera-PRO, ModelSim, and Icarus Verilog
// Author: Julio Tito (Rutgers University - ECE)
// =========================================================================

`timescale 1ns / 1ps

module tb_fir6;

    // Parameters
    localparam DATA_WIDTH = 8;
    localparam NUM_TAPS   = 6;
    localparam SUM_WIDTH  = 12;
    localparam CLK_PERIOD = 10; // 100 MHz clock (10 ns period)

    // Signals
    reg                   clk;
    reg                   rst;
    reg  [DATA_WIDTH-1:0] x_in;
    wire [DATA_WIDTH-1:0] y_out;

    // Debug probe wires
    wire [DATA_WIDTH-1:0] x0, x1, x2, x3, x4, x5;
    wire [SUM_WIDTH-1:0]  sum_dbg;

    // Verification bookkeeping
    integer error_count = 0;
    integer test_count  = 0;
    integer i;

    // Stimulus and Golden Verification Arrays
    reg [7:0] ramp_vec [0:15];
    reg [7:0] golden_ramp_y [0:15];

    // Device Under Test (DUT)
    fir6 #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_TAPS(NUM_TAPS),
        .SUM_WIDTH(SUM_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .x_in(x_in),
        .y_out(y_out),
        .x0(x0), .x1(x1), .x2(x2), .x3(x3), .x4(x4), .x5(x5),
        .sum_dbg(sum_dbg)
    );

    // 100 MHz Reference Clock Generation
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // VCD Waveform Dump
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_fir6);
    end

    // Prepopulate stimulus and cycle-accurate golden responses
    initial begin
        ramp_vec[0]=8'd10;   ramp_vec[1]=8'd20;   ramp_vec[2]=8'd30;   ramp_vec[3]=8'd40;
        ramp_vec[4]=8'd50;   ramp_vec[5]=8'd60;   ramp_vec[6]=8'd70;   ramp_vec[7]=8'd80;
        ramp_vec[8]=8'd90;   ramp_vec[9]=8'd100;  ramp_vec[10]=8'd110; ramp_vec[11]=8'd120;
        ramp_vec[12]=8'd130; ramp_vec[13]=8'd140; ramp_vec[14]=8'd150; ramp_vec[15]=8'd160;

        // Cycle-accurate registered output: y_out = (sum_{k=0}^5 r_k) >> 3
        golden_ramp_y[0]  = 8'd0;   // sum=0   -> y=0
        golden_ramp_y[1]  = 8'd0;   // sum=10  -> y=0 (registered next cycle)
        golden_ramp_y[2]  = 8'd1;   // sum=30  -> y=1  (10 >> 3 = 1)
        golden_ramp_y[3]  = 8'd3;   // sum=60  -> y=3  (30 >> 3 = 3)
        golden_ramp_y[4]  = 8'd7;   // sum=100 -> y=7  (60 >> 3 = 7)
        golden_ramp_y[5]  = 8'd12;  // sum=150 -> y=12 (100 >> 3 = 12)
        golden_ramp_y[6]  = 8'd18;  // sum=210 -> y=18 (150 >> 3 = 18)
        golden_ramp_y[7]  = 8'd26;  // sum=270 -> y=26 (210 >> 3 = 26)
        golden_ramp_y[8]  = 8'd33;  // sum=330 -> y=33 (270 >> 3 = 33)
        golden_ramp_y[9]  = 8'd41;  // sum=390 -> y=41 (330 >> 3 = 41)
        golden_ramp_y[10] = 8'd48;  // sum=450 -> y=48 (390 >> 3 = 48)
        golden_ramp_y[11] = 8'd56;  // sum=510 -> y=56 (450 >> 3 = 56)
        golden_ramp_y[12] = 8'd63;  // sum=570 -> y=63 (510 >> 3 = 63)
        golden_ramp_y[13] = 8'd71;  // sum=630 -> y=71 (570 >> 3 = 71)
        golden_ramp_y[14] = 8'd78;  // sum=690 -> y=78 (630 >> 3 = 78)
        golden_ramp_y[15] = 8'd86;  // sum=750 -> y=86 (690 >> 3 = 86)
    end

    // Main Test Sequence
    initial begin
        $display("=================================================================");
        $display("STARTING AUTOMATED SELF-CHECKING VERIFICATION: tb_fir6");
        $display("=================================================================");

        // -------------------------------------------------------------
        // Test 1: Synchronous Reset Assert & Deassert
        // -------------------------------------------------------------
        rst  = 1'b1;
        x_in = 8'd0;
        @(posedge clk);
        @(posedge clk);

        test_count = test_count + 1;
        if (y_out !== 8'd0 || sum_dbg !== 12'd0 || x0 !== 8'd0) begin
            $display("[FAIL] Test 1: Reset did not clear internal registers.");
            error_count = error_count + 1;
        end else begin
            $display("[PASS] Test 1: Synchronous Reset successfully cleared all taps & output.");
        end

        // Deassert reset
        rst = 1'b0;

        // -------------------------------------------------------------
        // Test 2: Dynamic 16-Sample Ramp Stimulus & Verification
        // -------------------------------------------------------------
        $display("-----------------------------------------------------------------");
        $display("Executing Test 2: 16-Sample Ramp Stimulus Verification");
        $display(" time  rst  x_in | x0  x1  x2  x3  x4  x5 | sum_dbg | y_out | Exp");

        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            x_in <= ramp_vec[i];
            #1; // Sample immediately following clock edge
            test_count = test_count + 1;
            $display("%4t   %b   %3d | %3d %3d %3d %3d %3d %3d |   %4d  |  %3d  | %3d",
                     $time, rst, x_in, x0, x1, x2, x3, x4, x5, sum_dbg, y_out, golden_ramp_y[i]);

            if (y_out !== golden_ramp_y[i]) begin
                $display("[FAIL] Sample %0d: Expected y_out = %0d, got %0d", i, golden_ramp_y[i], y_out);
                error_count = error_count + 1;
            end
        end

        // Flush remaining pipeline stages
        repeat (6) @(posedge clk);

        // -------------------------------------------------------------
        // Test 3: Steady-State DC Gain Validation (x_in = 64)
        // -------------------------------------------------------------
        $display("-----------------------------------------------------------------");
        $display("Executing Test 3: DC Step Response Settling (x_in = 64)");
        x_in = 8'd64; // Constant step input
        repeat (8) @(posedge clk); // Allow delay line to saturate with 64
        #1;
        test_count = test_count + 1;

        // Steady-state calculation: 6 taps * 64 = 384; 384 >> 3 = 48 (Gain = 6/8 = 0.75)
        if (y_out === 8'd48) begin
            $display("[PASS] Test 3: Steady-state DC gain verified: x_in=64 -> y_out=48 (Expected: 48)");
        end else begin
            $display("[FAIL] Test 3: DC gain mismatch: got %0d, expected 48", y_out);
            error_count = error_count + 1;
        end

        // -------------------------------------------------------------
        // Test Summary & Final Status
        // -------------------------------------------------------------
        $display("=================================================================");
        if (error_count == 0) begin
            $display("VERIFICATION RESULT: ALL TESTS PASSED (100%% FUNCTIONAL PASS RATE)");
            $display("Total Assertions Evaluated: %0d | Errors: 0", test_count);
        end else begin
            $display("VERIFICATION RESULT: TEST FAILED with %0d errors", error_count);
        end
        $display("=================================================================");

        $finish;
    end

endmodule

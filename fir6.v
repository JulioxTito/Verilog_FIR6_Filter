// =========================================================================
// Module: fir6
// Description: Parameterized 6-Tap Moving Average FIR Filter Core
// Architecture: Synchronous Tapped Delay Line with Multiplierless Adder-Tree
// Author: Julio Tito (Rutgers University - ECE)
// =========================================================================

`timescale 1ns / 1ps

module fir6 #(
    parameter DATA_WIDTH = 8,   // Input/Output data sample bit-width
    parameter NUM_TAPS   = 6,   // Number of discrete filter taps
    parameter SUM_WIDTH  = 12,  // Internal accumulator width (ceil(log2(6*255)) = 11 bits)
    parameter SHIFT_DIV  = 3    // Hardwired bit-shift scaler (>> 3 divides by 8)
) (
    input  wire                  clk,
    input  wire                  rst,    
    input  wire [DATA_WIDTH-1:0] x_in,
    output reg  [DATA_WIDTH-1:0] y_out,

    // Debug probe outputs for waveform and hardware inspection
    output wire [DATA_WIDTH-1:0] x0,
    output wire [DATA_WIDTH-1:0] x1,
    output wire [DATA_WIDTH-1:0] x2,
    output wire [DATA_WIDTH-1:0] x3,
    output wire [DATA_WIDTH-1:0] x4,
    output wire [DATA_WIDTH-1:0] x5,
    output wire [SUM_WIDTH-1:0]  sum_dbg
);

    // ---------------------------------------------------------------------
    // 1. Synchronous Tapped Delay Line (Shift Register Cascade)
    // ---------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] r0, r1, r2, r3, r4, r5;

    // Direct mapping to probe taps for real-time telemetry and waveform analysis
    assign x0 = r0;
    assign x1 = r1;
    assign x2 = r2;
    assign x3 = r3;
    assign x4 = r4;
    assign x5 = r5;

    // ---------------------------------------------------------------------
    // 2. Multiplierless Balanced Adder-Tree (Area & Timing Optimized)
    // ---------------------------------------------------------------------
    // Level 1: Pairwise additions across delay line taps (3 parallel adders)
    wire [DATA_WIDTH:0]   s01 = r0 + r1; // 9-bit intermediate sum
    wire [DATA_WIDTH:0]   s23 = r2 + r3; // 9-bit intermediate sum
    wire [DATA_WIDTH:0]   s45 = r4 + r5; // 9-bit intermediate sum

    // Level 2: Second-level parallel summation
    wire [DATA_WIDTH+1:0] s0123 = s01 + s23; // 10-bit intermediate sum

    // Level 3: Final accumulation bus (zero-extended to SUM_WIDTH)
    // Maximum theoretical sum: 6 * 255 = 1530 <= 2^11 - 1 (fits inside 12-bit bus)
    wire [SUM_WIDTH-1:0]  sum   = s0123 + {2'b00, s45};
    assign sum_dbg = sum;

    // ---------------------------------------------------------------------
    // 3. Power-of-Two Bit-Shift Scaler (Multiplierless Normalization)
    // ---------------------------------------------------------------------
    // Bit-shift right by 3 divides by 8 (hardware approximation of 1/6 filter tap weights)
    wire [SUM_WIDTH-1:0] scaled = sum >> SHIFT_DIV;

    // ---------------------------------------------------------------------
    // 4. Synchronous Sequential Register Commit
    // ---------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            r0    <= {DATA_WIDTH{1'b0}};
            r1    <= {DATA_WIDTH{1'b0}};
            r2    <= {DATA_WIDTH{1'b0}};
            r3    <= {DATA_WIDTH{1'b0}};
            r4    <= {DATA_WIDTH{1'b0}};
            r5    <= {DATA_WIDTH{1'b0}};
            y_out <= {DATA_WIDTH{1'b0}};
        end else begin
            // Shift in new input sample into the delay line
            r5 <= r4;
            r4 <= r3;
            r3 <= r2;
            r2 <= r1;
            r1 <= r0;
            r0 <= x_in;

            // Register quantized 8-bit output (1-cycle latency pipeline register)
            y_out <= scaled[DATA_WIDTH-1:0];
        end
    end

endmodule

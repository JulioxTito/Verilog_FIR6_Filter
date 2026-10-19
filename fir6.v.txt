
module fir6 (
    input  wire        clk,
    input  wire        rst,    
    input  wire [7:0]  x_in,
    output reg  [7:0]  y_out,

    // Debug outputs for waveforms
    output wire [7:0]  x0,
    output wire [7:0]  x1,
    output wire [7:0]  x2,
    output wire [7:0]  x3,
    output wire [7:0]  x4,
    output wire [7:0]  x5,
    output wire [11:0] sum_dbg
);

    // Delay line registers 
    reg [7:0] r0, r1, r2, r3, r4, r5;

    assign x0 = r0;
    assign x1 = r1;
    assign x2 = r2;
    assign x3 = r3;
    assign x4 = r4;
    assign x5 = r5;

    // Sum fits in 12 bits: max 6*255 = 1530
    wire [11:0] sum = {4'b0, r0} + {4'b0, r1} + {4'b0, r2} + {4'b0, r3} + {4'b0, r4} + {4'b0, r5};
    assign sum_dbg = sum;


    wire [11:0] scaled = sum >> 3;  // divide by 8

    always @(posedge clk) begin
        if (rst) begin
            r0    <= 8'd0;
            r1    <= 8'd0;
            r2    <= 8'd0;
            r3    <= 8'd0;
            r4    <= 8'd0;
            r5    <= 8'd0;
            y_out <= 8'd0;
        end else begin
            // Shift in new sample
            r5 <= r4;
            r4 <= r3;
            r3 <= r2;
            r2 <= r1;
            r1 <= r0;
            r0 <= x_in;

            // Output quantized (8-bit)
            y_out <= scaled[7:0];
        end
    end

endmodule

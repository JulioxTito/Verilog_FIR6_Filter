# 6-Tap Moving Average FIR Filter (Verilog HDL)

## Overview

A parameterizable, synchronous 6-tap moving average Finite Impulse Response (FIR) filter core modeled in structural Verilog. The hardware implements discrete-time smoothing over a sliding window of the six most recent 8-bit data samples, utilizing zero-overhead bit-shift division to eliminate hardware multipliers and optimize logic utilization.

---

## Architecture & Hardware Implementation

### 1. Shift Register Delay Line
Incoming discrete-time samples (`x_in`, 8-bit unsigned) pass through a 6-stage tapped delay line (`r0` to `r5`) clocked on the rising edge. The register chain acts as a sliding FIFO memory buffer containing the current sample and previous 5 historical samples.

### 2. Multiplierless Accumulation Tree
Standard FIR filters require area-heavy dedicated DSP multipliers for each tap. Because this design utilizes uniform unity tap weights ($h[k] = 1$), tap products simplify into direct parallel accumulation:

$$\text{sum}[n] = \sum_{k=0}^{5} x[n-k] = r_0 + r_1 + r_2 + r_3 + r_4 + r_5$$

* **Bit-Growth Sizing:** With 8-bit inputs ($0 \le x \le 255$), the peak theoretical summation reaches $6 \times 255 = 1530$. The accumulator bus is zero-extended to 12 bits (`wire [11:0] sum`), guaranteeing that no arithmetic overflow or clipping occurs.

### 3. Power-of-Two Scaling
To normalize the output without an area-intensive iterative division unit, the accumulator sum is scaled via a hardwired right-shift by 3:

$$y_{\text{scaled}} = \text{sum} \gg 3 \quad \left(\approx \frac{\text{sum}}{8}\right)$$

The final filtered result is registered into `y_out[7:0]` on the subsequent clock edge.

---

## Module Ports & Interface

| Port Name | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `clk` | Input | 1-bit | System clock (rising-edge active) |
| `rst` | Input | 1-bit | Synchronous reset (active-high) |
| `x_in` | Input | 8-bit | Discrete input sample bus |
| `y_out` | Output | 8-bit | Filtered output response |
| `x0` - `x5` | Output | 8-bit | Tap probe outputs for waveform debugging |
| `sum_dbg` | Output | 12-bit | Internal accumulator probe bus |

---

## Verification & Testbench

The module is verified via `tb_fir6.v`:
* **Clock Generation:** 100 MHz reference clock (10 ns period).
* **Reset Sequencing:** Synchronous reset assertion for 2 full clock cycles.
* **Ramp Stimulus:** Applies a 16-sample ramp array ($10, 20, 30, \dots, 160$) to verify delay-line shifting, accumulation accuracy, and output settling over time.
* **Automated Logging:** Employs `$monitor` for real-time console tracing and `$dumpvars` for VCD waveform inspection.

---

## EDA Tools

* **HDL Language:** Verilog-2001
* **Simulation & Waveforms:** ModelSim / Icarus Verilog + GTKWave
* **Synthesis Compatibility:** Intel Quartus Prime / Xilinx Vivado (Standard Cell & FPGA)

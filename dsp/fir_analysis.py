import math
import cmath

def compute_frequency_response(num_points=500):
    # h = [1/8, 1/8, 1/8, 1/8, 1/8, 1/8] (scaled moving average)
    h = [1.0 / 8.0] * 6
    w_list = []
    mag_db_list = []
    mag_linear_list = []

    for i in range(num_points):
        w = (math.pi * i) / (num_points - 1)  # 0 to pi (rad/sample)
        # H(e^jw) = sum_{k=0}^5 h[k] * e^{-j*w*k}
        H = sum(h[k] * cmath.exp(-1j * w * k) for k in range(6))
        mag = abs(H)
        mag_db = 20 * math.log10(max(mag, 1e-6))
        w_list.append(w)
        mag_db_list.append(mag_db)
        mag_linear_list.append(mag)

    return w_list, mag_db_list, mag_linear_list

def generate_svg_plot(w_list, mag_db_list, output_path):
    # Plot specifications
    width, height = 1100, 520
    pad_left, pad_right = 80, 50
    pad_top, pad_bot = 80, 60

    # Panel 1: Frequency Response (x: 80 to 650, y: 80 to 450)
    p1_w = 580
    p1_h = 360
    p1_x0, p1_y0 = 80, 80

    # Panel 2: Impulse Response (x: 740 to 1040, y: 80 to 450)
    p2_w = 310
    p2_h = 360
    p2_x0, p2_y0 = 740, 80

    # Frequency plot scaling: w: 0 to pi -> 0 to 1 (normalized); dB: -40 to 0 dB
    db_min, db_max = -40, 0
    def map_p1(w_norm, db):
        x = p1_x0 + w_norm * p1_w
        clamped_db = max(db_min, min(db_max, db))
        y = p1_y0 + (db_max - clamped_db) / (db_max - db_min) * p1_h
        return x, y

    # Generate path for frequency response
    path_d = []
    for i, (w, db) in enumerate(zip(w_list, mag_db_list)):
        w_norm = w / math.pi
        x, y = map_p1(w_norm, db)
        cmd = "M" if i == 0 else "L"
        path_d.append(f"{cmd} {x:.1f} {y:.1f}")
    curve_path = " ".join(path_d)

    # Impulse response values (n=0..7)
    # y = [0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0, 0]
    impulse_stems = ""
    for n in range(8):
        val = 0.125 if 0 <= n <= 5 else 0.0
        x_stem = p2_x0 + 35 + n * 32
        y_base = p2_y0 + p2_h - 40
        y_top = y_base - (val / 0.16) * (p2_h - 80)
        impulse_stems += f"""
        <line x1="{x_stem}" y1="{y_base}" x2="{x_stem}" y2="{y_top}" stroke="#3fb950" stroke-width="2.5"/>
        <circle cx="{x_stem}" cy="{y_top}" r="5" fill="#3fb950"/>
        <text x="{x_stem}" y="{y_base + 18}" fill="#8b949e" font-size="10" text-anchor="middle">{n}</text>
        """

    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="100%" height="100%" style="background:#0d1117; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0e131f"/>
      <stop offset="100%" stop-color="#161b26"/>
    </linearGradient>
    <filter id="shadow">
      <feDropShadow dx="0" dy="4" stdDeviation="4" flood-color="#000" flood-opacity="0.4"/>
    </filter>
  </defs>

  <!-- Frame -->
  <rect x="15" y="15" width="{width - 30}" height="{height - 30}" rx="14" fill="url(#bg)" stroke="#30363d" stroke-width="1.5" filter="url(#shadow)"/>

  <!-- Main Title -->
  <text x="45" y="48" fill="#f0f6fc" font-size="18" font-weight="700">6-TAP MOVING AVERAGE FIR FILTER: FREQUENCY &amp; IMPULSE RESPONSE</text>
  <text x="45" y="68" fill="#8b949e" font-size="11">MATLAB / Python Fixed-Point Verification Model • Discrete-Time Transfer Function H(z) = ⅛ (1 - z⁻⁶) / (1 - z⁻¹)</text>

  <!-- ==================== PANEL 1: MAGNITUDE RESPONSE ==================== -->
  <rect x="{p1_x0}" y="{p1_y0}" width="{p1_w}" height="{p1_h}" fill="#161b22" stroke="#30363d" stroke-width="1" rx="6"/>
  <text x="{p1_x0 + 15}" y="{p1_y0 + 25}" fill="#58a6ff" font-size="13" font-weight="700">Normalized Magnitude Response |H(e^jω)| (dB)</text>

  <!-- Grid Lines & dB Axis Labels -->
  <!-- 0 dB -->
  <line x1="{p1_x0}" y1="{p1_y0}" x2="{p1_x0 + p1_w}" y2="{p1_y0}" stroke="#30363d" stroke-width="1" stroke-dasharray="3 3"/>
  <text x="{p1_x0 - 8}" y="{p1_y0 + 4}" fill="#8b949e" font-size="10" text-anchor="end">0 dB</text>

  <!-- -2.5 dB (DC Gain) -->
  <line x1="{p1_x0}" y1="{map_p1(0, -2.5)[1]}" x2="{p1_x0 + p1_w}" y2="{map_p1(0, -2.5)[1]}" stroke="#58a6ff" stroke-width="1" stroke-dasharray="4 2" stroke-opacity="0.5"/>
  <text x="{p1_x0 - 8}" y="{map_p1(0, -2.5)[1] + 4}" fill="#58a6ff" font-size="10" text-anchor="end">-2.5 dB</text>

  <!-- -10 dB -->
  <line x1="{p1_x0}" y1="{map_p1(0, -10)[1]}" x2="{p1_x0 + p1_w}" y2="{map_p1(0, -10)[1]}" stroke="#30363d" stroke-width="1" stroke-dasharray="3 3"/>
  <text x="{p1_x0 - 8}" y="{map_p1(0, -10)[1] + 4}" fill="#8b949e" font-size="10" text-anchor="end">-10 dB</text>

  <!-- -20 dB -->
  <line x1="{p1_x0}" y1="{map_p1(0, -20)[1]}" x2="{p1_x0 + p1_w}" y2="{map_p1(0, -20)[1]}" stroke="#30363d" stroke-width="1" stroke-dasharray="3 3"/>
  <text x="{p1_x0 - 8}" y="{map_p1(0, -20)[1] + 4}" fill="#8b949e" font-size="10" text-anchor="end">-20 dB</text>

  <!-- -30 dB -->
  <line x1="{p1_x0}" y1="{map_p1(0, -30)[1]}" x2="{p1_x0 + p1_w}" y2="{map_p1(0, -30)[1]}" stroke="#30363d" stroke-width="1" stroke-dasharray="3 3"/>
  <text x="{p1_x0 - 8}" y="{map_p1(0, -30)[1] + 4}" fill="#8b949e" font-size="10" text-anchor="end">-30 dB</text>

  <!-- -40 dB -->
  <line x1="{p1_x0}" y1="{map_p1(0, -40)[1]}" x2="{p1_x0 + p1_w}" y2="{map_p1(0, -40)[1]}" stroke="#30363d" stroke-width="1"/>
  <text x="{p1_x0 - 8}" y="{map_p1(0, -40)[1] + 4}" fill="#8b949e" font-size="10" text-anchor="end">-40 dB</text>

  <!-- Frequency Grid Lines -->
  <!-- 0.33 pi (Null 1: fs/6) -->
  <line x1="{map_p1(1/3, 0)[0]}" y1="{p1_y0}" x2="{map_p1(1/3, 0)[0]}" y2="{p1_y0 + p1_h}" stroke="#f85149" stroke-width="1" stroke-dasharray="3 3" stroke-opacity="0.6"/>
  <text x="{map_p1(1/3, 0)[0]}" y="{p1_y0 + p1_h + 18}" fill="#f85149" font-size="10" text-anchor="middle">π/3 (Null 1)</text>

  <!-- 0.50 pi -->
  <line x1="{map_p1(0.5, 0)[0]}" y1="{p1_y0}" x2="{map_p1(0.5, 0)[0]}" y2="{p1_y0 + p1_h}" stroke="#30363d" stroke-width="1" stroke-dasharray="3 3"/>
  <text x="{map_p1(0.5, 0)[0]}" y="{p1_y0 + p1_h + 18}" fill="#8b949e" font-size="10" text-anchor="middle">0.5π</text>

  <!-- 0.67 pi (Null 2: fs/3) -->
  <line x1="{map_p1(2/3, 0)[0]}" y1="{p1_y0}" x2="{map_p1(2/3, 0)[0]}" y2="{p1_y0 + p1_h}" stroke="#f85149" stroke-width="1" stroke-dasharray="3 3" stroke-opacity="0.6"/>
  <text x="{map_p1(2/3, 0)[0]}" y="{p1_y0 + p1_h + 18}" fill="#f85149" font-size="10" text-anchor="middle">2π/3 (Null 2)</text>

  <!-- pi -->
  <line x1="{map_p1(1.0, 0)[0]}" y1="{p1_y0}" x2="{map_p1(1.0, 0)[0]}" y2="{p1_y0 + p1_h}" stroke="#30363d" stroke-width="1"/>
  <text x="{map_p1(1.0, 0)[0]}" y="{p1_y0 + p1_h + 18}" fill="#8b949e" font-size="10" text-anchor="middle">π (fs/2)</text>
  <text x="{p1_x0}" y="{p1_y0 + p1_h + 18}" fill="#8b949e" font-size="10" text-anchor="middle">0 (DC)</text>

  <!-- Frequency axis title -->
  <text x="{p1_x0 + p1_w/2}" y="{p1_y0 + p1_h + 38}" fill="#8b949e" font-size="11" text-anchor="middle">Normalized Frequency (rad / sample)</text>

  <!-- Curve Plot -->
  <path d="{curve_path}" fill="none" stroke="#58a6ff" stroke-width="2.5"/>

  <!-- Annotations on Curve -->
  <!-- DC point -->
  <circle cx="{map_p1(0, -2.5)[0]}" cy="{map_p1(0, -2.5)[1]}" r="4" fill="#58a6ff"/>
  <text x="{map_p1(0, -2.5)[0] + 12}" y="{map_p1(0, -2.5)[1] - 8}" fill="#58a6ff" font-size="10" font-weight="600">DC Passband: -2.50 dB (6/8 gain)</text>

  <!-- Null 1 marker -->
  <circle cx="{map_p1(1/3, -38)[0]}" cy="{map_p1(1/3, -38)[1]}" r="4" fill="#f85149"/>
  <text x="{map_p1(1/3, -38)[0] + 8}" y="{map_p1(1/3, -38)[1] - 8}" fill="#f85149" font-size="9">Transmission Zero (Null)</text>

  <!-- Null 2 marker -->
  <circle cx="{map_p1(2/3, -38)[0]}" cy="{map_p1(2/3, -38)[1]}" r="4" fill="#f85149"/>


  <!-- ==================== PANEL 2: IMPULSE RESPONSE ==================== -->
  <rect x="{p2_x0}" y="{p2_y0}" width="{p2_w}" height="{p2_h}" fill="#161b22" stroke="#30363d" stroke-width="1" rx="6"/>
  <text x="{p2_x0 + 15}" y="{p2_y0 + 25}" fill="#3fb950" font-size="13" font-weight="700">Impulse Response h[n]</text>

  <!-- Baseline -->
  <line x1="{p2_x0 + 20}" y1="{p2_y0 + p2_h - 40}" x2="{p2_x0 + p2_w - 20}" y2="{p2_y0 + p2_h - 40}" stroke="#30363d" stroke-width="1"/>

  <!-- Stems -->
  {impulse_stems}

  <!-- Impulse response labels -->
  <text x="{p2_x0 + p2_w/2}" y="{p2_y0 + p2_h - 10}" fill="#8b949e" font-size="11" text-anchor="middle">Sample Index (n)</text>
  <text x="{p2_x0 + 25}" y="{p2_y0 + 130}" fill="#3fb950" font-size="11" font-weight="600">h[n] = ⅛ = 0.125</text>
  <text x="{p2_x0 + 25}" y="{p2_y0 + 148}" fill="#8b949e" font-size="9">Uniform 6-tap weights</text>
  <text x="{p2_x0 + 25}" y="{p2_y0 + 163}" fill="#8b949e" font-size="9">for n ∈ [0, 5], 0 elsewhere</text>
</svg>
"""

    with open(output_path, "w", encoding="utf-8") as f:
        f.write(svg)
    print(f"SVG saved to {output_path}")

if __name__ == "__main__":
    w, db, lin = compute_frequency_response()
    out = r"C:\Users\Julio\.gemini\antigravity\scratch\Verilog_FIR6_Filter\docs\fir6_frequency_response.svg"
    generate_svg_plot(w, db, out)

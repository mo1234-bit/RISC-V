import math

N = 512
scale = 2**23  # matches your RTL

with open("rsqrt_lut_512x24.hex", "w") as f:
    for i in range(N):
        lut_input = 1.0 + (i / 512.0)
        rsqrt_val = 1.0 / math.sqrt(lut_input)
        val = int(rsqrt_val * scale)  # trunc like $rtoi (positive)
        val &= (1<<24)-1              # keep 24 bits
        f.write(f"{val:06X}\n")
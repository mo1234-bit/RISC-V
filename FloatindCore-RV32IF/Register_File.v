// 32x32-bit Register File
// Supports two read ports and one write port
// Register x0 is always zero (RISC-V convention)

module Register_File(
    input clk, rst_n,        // Clock and active-low reset
    input WE3,               // Write enable for write port
    input [4:0] A1, A2, A3, // Read addresses (A1,A2) and write address (A3)
    input [31:0] WD3,        // Write data inputn
    output [31:0] RD1, RD2  // Read data outputs
);

    // ------------------------------
    // Register array: 32 registers, 32-bit each
    // ------------------------------
    reg [31:0] Register [31:0];

    // ------------------------------
    // Write logic (synchronous)
    // ------------------------------
    always @(posedge clk) begin
        // Only write if WE3 is high and write address != x0
        if (WE3 & (A3 != 5'h00)) begin
            Register[A3] <= WD3;
            // x0 must always stay zero
            Register[0] <= 32'h00000000;
        end 
    end

    // ------------------------------
    // Read logic (combinational)
    // ------------------------------
    // Forwarding: if reading the same register that is being written this cycle,
    // return the new value WD3 instead of old stored value
    assign RD1 = (rst_n == 1'b0) ? 32'd0 :       // Reset condition
                 (A1 == 5'h00) ? 32'h00000000 :  // x0 is always zero
                 (WE3 && (A3 == A1) && (A3 != 5'h00)) ? WD3 :  // Forwarding
                 Register[A1];                    // Otherwise, read stored value
                 
    assign RD2 = (rst_n == 1'b0) ? 32'd0 :
                 (A2 == 5'h00) ? 32'h00000000 :
                 (WE3 && (A3 == A2) && (A3 != 5'h00)) ? WD3 :
                 Register[A2];

    // ------------------------------
    // Initialize registers to 0
    // ------------------------------
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            Register[i] = 32'h00000000;
        Register[0] = 32'h00000000; // Ensure x0 is zero
    end

endmodule


module tb_fsqrt_complete;

    // Clock and reset
    reg clk;
    reg reset;
    
    // DUT signals
    reg start;
    reg [31:0] operand;
    wire [31:0] result;
    wire done;
    wire busy;
    wire [3:0] debug_state;
    
    // Test tracking
    integer test_count;
    integer pass_count;
    integer fail_count;
    
    // Instantiate DUT
    fsqrt_newton_raphson #(
        .ITERATIONS(4)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .operand(operand),
        .result(result),
        .done(done),
        .busy(busy),
        .debug_state(debug_state)
    );
    
    // Clock generation: 100 MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Timeout watchdog
    initial begin
        #1000000;  // 1ms timeout
        $display("\n*** ERROR: Simulation timeout! ***");
        $display("Test may be stuck. Check your FPU modules.");
        $finish;
    end
    
    // Helper task: Run one test
    task run_test;
        input [31:0] input_val;
        input [31:0] expected_val;
        input [255:0] test_name;
        reg [31:0] actual;
        real input_float, expected_float, actual_float, error;
    begin
        test_count = test_count + 1;
        
        $display("\n--- Test %0d: %s ---", test_count, test_name);
        $display("Input:    0x%08h", input_val);
        $display("Expected: 0x%08h", expected_val);
        
        // Start operation
        operand = input_val;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        // Wait for completion (with timeout)
        fork
            begin
                wait(done);
            end
            begin
                #50000;  // 50us timeout per test
                $display("*** Test timeout! ***");
            end
        join_any
        disable fork;
        
        if (done) begin
            actual = result;
            $display("Actual:   0x%08h", actual);
            
            // Check result (allow small floating-point error)
            if (actual == expected_val) begin
                $display("PASS - Exact match");
                pass_count = pass_count + 1;
            end else begin
                // Check if close enough (within 1 ULP for most cases)
                if ((actual[30:23] == expected_val[30:23]) &&  // Same exponent
                    (actual[22:0] >= expected_val[22:0] - 2) &&  // Mantissa within 2 ULPs
                    (actual[22:0] <= expected_val[22:0] + 2)) begin
                    $display("PASS - Within tolerance");
                    pass_count = pass_count + 1;
                end else begin
                    $display("FAIL - Result mismatch");
                    fail_count = fail_count + 1;
                end
            end
        end else begin
            $display("FAIL - Timeout");
            fail_count = fail_count + 1;
        end
        
        // Wait a bit before next test
        repeat(10) @(posedge clk);
    end
    endtask
    
    // Main test sequence
    initial begin
        $dumpfile("fsqrt_tb.vcd");
        $dumpvars(0, tb_fsqrt_complete);
        
        // Initialize
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        start = 0;
        operand = 0;
        
        // Reset sequence
        $display("\n========================================");
        $display("FSQRT Newton-Raphson Testbench");
        $display("========================================");
        reset = 0;
        repeat(5) @(posedge clk);
        reset = 1;
        repeat(5) @(posedge clk);
        
        // Test cases
        
        // Basic tests
        run_test(32'h40800000, 32'h40000000, "sqrt(4.0) = 2.0");
        run_test(32'h40000000, 32'h3FB504F3, "sqrt(2.0) = 1.414...");
        run_test(32'h3F800000, 32'h3F800000, "sqrt(1.0) = 1.0");
        run_test(32'h3F000000, 32'h3F3504F3, "sqrt(0.5) = 0.707...");
        run_test(32'h3E800000, 32'h3F000000, "sqrt(0.25) = 0.5");
        
        // Larger numbers
        run_test(32'h41200000, 32'h40A00000, "sqrt(10.0) = 3.162...");
        run_test(32'h42C80000, 32'h41200000, "sqrt(100.0) = 10.0");
        run_test(32'h447A0000, 32'h42C80000, "sqrt(1000.0) = 31.62...");
        
        // Small numbers
        run_test(32'h3C23D70A, 32'h3DCCCCCD, "sqrt(0.01) = 0.1");
        run_test(32'h3A83126F, 32'h3C23D70A, "sqrt(0.001) = 0.0316...");
        
        // Edge cases - Special values
        run_test(32'h00000000, 32'h00000000, "sqrt(+0) = +0");
        run_test(32'h80000000, 32'h80000000, "sqrt(-0) = -0");
        run_test(32'h7F800000, 32'h7F800000, "sqrt(+inf) = +inf");
        run_test(32'hBF800000, 32'h7FC00000, "sqrt(-1.0) = NaN");
        run_test(32'h7FC00000, 32'h7FC00000, "sqrt(NaN) = NaN");
        
        // Powers of 2 (should be exact)
        run_test(32'h3F000000, 32'h3F3504F3, "sqrt(0.5)");
        run_test(32'h40800000, 32'h40000000, "sqrt(4.0)");
        run_test(32'h41800000, 32'h40800000, "sqrt(16.0)");
        run_test(32'h42800000, 32'h41800000, "sqrt(64.0)");
        
        // Print summary
        repeat(10) @(posedge clk);
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Total tests: %0d", test_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("\n*** ALL TESTS PASSED ***");
        end else begin
            $display("\n*** SOME TESTS FAILED ***");
        end
        
        $display("========================================\n");
        $finish;
    end
    
    // Monitor state changes
    always @(debug_state) begin
        case (debug_state)
            4'd0: $display("[%0t] State: IDLE", $time);
            4'd1: $display("[%0t] State: CHECK_SPECIAL", $time);
            4'd2: $display("[%0t] State: INIT_GUESS", $time);
            4'd3: $display("[%0t] State: DIV_START", $time);
            4'd4: $display("[%0t] State: DIV_WAIT", $time);
            4'd5: $display("[%0t] State: ADD_START", $time);
            4'd6: $display("[%0t] State: ADD_WAIT", $time);
            4'd7: $display("[%0t] State: MUL_START", $time);
            4'd8: $display("[%0t] State: MUL_WAIT", $time);
            4'd9: $display("[%0t] State: FINISH", $time);
        endcase
    end

endmodule
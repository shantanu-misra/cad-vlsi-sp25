module risc_spm_tb;
    // Testbench signals.
    logic       clk;
    logic       reset;
    
    // External memory interface signals.
    logic       prog_mode;
    logic [7:0] prog_addr;
    logic       prog_write;
    logic [7:0] prog_data_in;
    logic [7:0] prog_data_out;
    
    // Debug/status outputs from the DUT.
    logic [7:0] output_data;
    logic [7:0] pc_debug;
    logic [7:0] ir_debug;
    logic [2:0] state_debug;
    logic       halt_flag;
    
    // For readability.
    string state_names[8] = {"S_RESET", "S_FETCH", "S_DECODE", "S_FETCH_IMM",
                             "S_EXECUTE", "S_MEMORY", "S_WB", "S_HALT"};
    string current_state;
    assign current_state = state_names[state_debug];
    
    // Instantiate the top module.
    risc_spm_top dut (
        .clk(clk),
        .reset(reset),
        .prog_mode(prog_mode),
        .prog_addr(prog_addr),
        .prog_write(prog_write),
        .prog_data_in(prog_data_in),
        .prog_data_out(prog_data_out),
        .output_data(output_data),
        .pc_debug(pc_debug),
        .ir_debug(ir_debug),
        .state_debug(state_debug),
        .halt_flag(halt_flag)
    );
    
    //--------------------------------------------------------------------------
    // Task: program_memory (writes one byte).
    task program_memory(input [7:0] addr, input [7:0] data);
        begin
            prog_mode    = 1;
            prog_addr    = addr;
            prog_data_in = data;
            prog_write   = 0;
            @(posedge clk);
            prog_write   = 1;
            @(posedge clk);
            @(posedge clk);
            prog_write   = 0;
            @(posedge clk);
        end
    endtask
    
    //--------------------------------------------------------------------------
    // Task: read_memory.
    task read_memory(input [7:0] addr, output [7:0] data);
        begin
            prog_mode  = 1;
            prog_addr  = addr;
            prog_write = 0;
            @(posedge clk);
            @(posedge clk);
            data = prog_data_out;
            @(posedge clk);
        end
    endtask
    
    //--------------------------------------------------------------------------
    // Task: verify_memory.
    task verify_memory(input [7:0] addr, input [7:0] expected);
        logic [7:0] read_data;
        begin
            read_memory(addr, read_data);
            if (read_data === expected)
                $display("PASS: Memory addr 0x%h = 0x%h (Expected: 0x%h)", addr, read_data, expected);
            else
                $display("FAIL: Memory addr 0x%h = 0x%h (Expected: 0x%h)", addr, read_data, expected);
        end
    endtask
    
    //--------------------------------------------------------------------------
    // Task: initialize_memory.
    // Programs a test program into memory based on the test name.
    // Immediate fields now point to data stored in higher memory addresses.
    task initialize_memory(input string test_name);
        begin
            $display("\nInitializing memory for test: %s", test_name);
            // Assert reset during programming.
            reset = 1;
            @(posedge clk); @(posedge clk);
            reset = 0;
            @(posedge clk);
            if (test_name == "basic_add") begin
                // Test 1: Basic addition.
                // RD R1 with immediate pointing to 0x20; RD R2 with immediate to 0x21;
                // then ADD R1,R0 and ADD R2,R0, then HALT.
                program_memory(8'h00, 8'b0101_00_01); // RD R1
                program_memory(8'h01, 8'h20);         // Immediate: address 0x20.
                program_memory(8'h02, 8'b0101_00_10); // RD R2
                program_memory(8'h03, 8'h21);         // Immediate: address 0x21.
                program_memory(8'h04, 8'b0001_01_00); // ADD R1,R0.
                program_memory(8'h05, 8'b0001_10_00); // ADD R2,R0.
                program_memory(8'h06, 8'b1111_00_00); // HALT.
                // Data:
                program_memory(8'h20, 8'h05);
                program_memory(8'h21, 8'h03);
            end
            else if (test_name == "subtraction") begin
                // Test 2: Subtraction: 10 - 3 = 7.
                program_memory(8'h00, 8'b0101_00_01); // RD R1.
                program_memory(8'h01, 8'h22);         // Immediate: address 0x22.
                program_memory(8'h02, 8'b0101_00_10); // RD R2.
                program_memory(8'h03, 8'h23);         // Immediate: address 0x23.
                program_memory(8'h04, 8'b0001_01_00); // ADD R1,R0.
                program_memory(8'h05, 8'b0010_10_00); // SUB R2,R0.
                program_memory(8'h06, 8'b1111_00_00); // HALT.
                program_memory(8'h22, 8'h0A);         // Data: 10.
                program_memory(8'h23, 8'h03);         // Data: 3.
            end
            else if (test_name == "logical_ops") begin
                // Test 3: Logical operations.
                program_memory(8'h00, 8'b0101_00_01); // RD R1.
                program_memory(8'h01, 8'h24);         // Immediate: addr 0x24.
                program_memory(8'h02, 8'b0101_00_10); // RD R2.
                program_memory(8'h03, 8'h25);         // Immediate: addr 0x25.
                program_memory(8'h04, 8'b0001_01_00); // ADD R1,R0.
                program_memory(8'h05, 8'b0011_10_00); // AND R2,R0.
                program_memory(8'h06, 8'b0100_00_11); // NOT R0,R3.
                program_memory(8'h07, 8'b1111_00_00); // HALT.
                program_memory(8'h24, 8'h0F);
                program_memory(8'h25, 8'h33);
            end
            else if (test_name == "complex_sequence") begin
                // Test 4: A sequence mixing ADD, SUB, AND.
                program_memory(8'h00, 8'b0101_00_01); // RD R1 from 0x26.
                program_memory(8'h01, 8'h26);
                program_memory(8'h02, 8'b0101_00_10); // RD R2 from 0x27.
                program_memory(8'h03, 8'h27);
                program_memory(8'h04, 8'b0001_01_10); // ADD R1,R2.
                program_memory(8'h05, 8'b0010_01_10); // SUB R1,R2.
                program_memory(8'h06, 8'b0011_01_10); // AND R1,R2.
                program_memory(8'h07, 8'b0001_10_00); // ADD R2,R0.
                program_memory(8'h08, 8'b1111_00_00); // HALT.
                program_memory(8'h26, 8'h05);
                program_memory(8'h27, 8'h03);
            end
            else if (test_name == "register_ops") begin
                // Test 5: Register operations.
                program_memory(8'h00, 8'b0101_00_00); // RD R0 from 0x28.
                program_memory(8'h01, 8'h28);
                program_memory(8'h02, 8'b0101_00_01); // RD R1 from 0x29.
                program_memory(8'h03, 8'h29);
                program_memory(8'h04, 8'b0101_00_10); // RD R2 from 0x2A.
                program_memory(8'h05, 8'h2A);
                program_memory(8'h06, 8'b0101_00_11); // RD R3 from 0x2B.
                program_memory(8'h07, 8'h2B);
                program_memory(8'h08, 8'b0001_01_00); // ADD R1,R0.
                program_memory(8'h09, 8'b0001_10_00); // ADD R2,R0.
                program_memory(8'h0A, 8'b0001_11_00); // ADD R3,R0.
                program_memory(8'h0B, 8'b1111_00_00); // HALT.
                program_memory(8'h28, 8'h01);
                program_memory(8'h29, 8'h02);
                program_memory(8'h2A, 8'h03);
                program_memory(8'h2B, 8'h04);
            end
            else if (test_name == "store_load") begin
                // Test 6: Store then load.
                // RD R1 from address 0x2C, then WR R1 writes that value to 0x30,
                // then RD R2 loads from 0x30.
                program_memory(8'h00, 8'b0101_00_01); // RD R1.
                program_memory(8'h01, 8'h2C);         // Immediate: 0x2C.
                program_memory(8'h02, 8'b0110_00_01); // WR R1.
                program_memory(8'h03, 8'h30);         // Immediate: 0x30.
                program_memory(8'h04, 8'b0101_00_10); // RD R2.
                program_memory(8'h05, 8'h30);         // Immediate: 0x30.
                program_memory(8'h06, 8'b1111_00_00); // HALT.
                program_memory(8'h2C, 8'h09);         // Data: 9.
            end
            else if (test_name == "branch_test") begin
                // Test 7: Branch test.
                // RD R1 from 0x2D with data 5, then BR jumps to 0x06
                // skipping an ADD instruction. Final R0 should equal 5.
                program_memory(8'h00, 8'b0101_00_01); // RD R1.
                program_memory(8'h01, 8'h2D);         // Immediate: 0x2D.
                program_memory(8'h02, 8'b0111_00_00); // BR.
                program_memory(8'h03, 8'h06);         // Immediate: jump target 0x06.
                program_memory(8'h04, 8'b0001_01_00); // ADD R1,R0 (should be skipped).
                program_memory(8'h05, 8'b0000_00_00); // NOP.
                program_memory(8'h06, 8'b1111_00_00); // HALT.
                program_memory(8'h2D, 8'h05);         // Data: 5.
            end
            else begin
                $display("Unknown test case: %s", test_name);
                $finish;
            end
        end
    endtask
    
    //--------------------------------------------------------------------------
    // Task: verify_results.
    // Check DUT's final R0 value against expected outcome.
    task verify_results(input string test_name);
        begin
            case (test_name)
                "basic_add": begin
                    if (output_data == 8'h08)
                        $display("TEST PASSED: basic_add - R0 = %h (Expected: 08)", output_data);
                    else
                        $display("TEST FAILED: basic_add - R0 = %h (Expected: 08)", output_data);
                end
                "subtraction": begin
                    if (output_data == 8'h07)
                        $display("TEST PASSED: subtraction - R0 = %h (Expected: 07)", output_data);
                    else
                        $display("TEST FAILED: subtraction - R0 = %h (Expected: 07)", output_data);
                end
                "logical_ops": begin
                    if (output_data == 8'h03)
                        $display("TEST PASSED: logical_ops - R0 = %h (Expected: 03)", output_data);
                    else
                        $display("TEST FAILED: logical_ops - R0 = %h (Expected: 03)", output_data);
                end
                "complex_sequence": begin
                    if (output_data == 8'h01)
                        $display("TEST PASSED: complex_sequence - R0 = %h (Expected: 01)", output_data);
                    else
                        $display("TEST FAILED: complex_sequence - R0 = %h (Expected: 01)", output_data);
                end
                "register_ops": begin
                    if (output_data == 8'h0A)
                        $display("TEST PASSED: register_ops - R0 = %h (Expected: 0A)", output_data);
                    else
                        $display("TEST FAILED: register_ops - R0 = %h (Expected: 0A)", output_data);
                end
                "store_load": begin
                    if (output_data == 8'h09)
                        $display("TEST PASSED: store_load - R0 = %h (Expected: 09)", output_data);
                    else
                        $display("TEST FAILED: store_load - R0 = %h (Expected: 09)", output_data);
                end
                "branch_test": begin
                    if (output_data == 8'h05)
                        $display("TEST PASSED: branch_test - R0 = %h (Expected: 05)", output_data);
                    else
                        $display("TEST FAILED: branch_test - R0 = %h (Expected: 05)", output_data);
                end
                default: begin
                    $display("Unknown test case for verification: %s", test_name);
                end
            endcase
        end
    endtask
    
    //--------------------------------------------------------------------------
    // Task: run_test.
    // Programs memory for a test, runs the simulation until the DUT asserts HALT,
    // then performs a result verification.
    task run_test(input string test_name);
        begin
            $display("\n--- Running Test: %s ---", test_name);
            initialize_memory(test_name);
            // Deassert reset and disable programming mode to start execution.
            reset = 0;
            prog_mode = 0;
            @(posedge clk);
            // Wait for HALT flag or timeout.
            fork
                begin : halt_monitor
                    wait(halt_flag);
                    @(posedge clk);
                    $display("--- Final Registers for %s ---", test_name);
                    $display("R0 = %h, PC = %h, IR = %h, State = %s", 
                              output_data, pc_debug, ir_debug, current_state);
                    verify_results(test_name);
                end
                begin : timeout_monitor
                    #2000;
                    $display("TEST FAILED: %s - Timeout reached without HALT", test_name);
                    $finish;
                end
            join_any
            disable fork;
        end
    endtask
    
    //--------------------------------------------------------------------------
    // Main Test Sequence: Run desired tests sequentially.
    initial begin
        $display("\n=== Starting RISC SPM Tests ===\n");
        run_test("basic_add");
        run_test("subtraction");
        run_test("logical_ops");
        run_test("complex_sequence");
        run_test("register_ops");
        $display("\n=== All Tests Complete ===\n");
        $finish;
    end
    
    //--------------------------------------------------------------------------
    // Clock generation.
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 ns clock period.
    end
    
    // Waveform dump.
    initial begin
        $dumpfile("risc_spm_wave.vcd");
        $dumpvars(0, risc_spm_tb);
    end
endmodule

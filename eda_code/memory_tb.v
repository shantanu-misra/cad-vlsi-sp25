// Improved Memory Testbench
// Tests memory read/write operations and reset behavior with proper timing
module memory_tb;
    // Testbench signals
    logic clk;
    logic reset;
    logic [7:0] address;
    logic write_enable;
    logic [7:0] data_in;
    logic [7:0] data_out;
    
    // Instantiate memory unit
    memory dut (
        .clk(clk),
        .reset(reset),
        .address(address),
        .write_enable(write_enable),
        .data_in(data_in),
        .data_out(data_out)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end
  
	// Waveform generation
    initial begin
        $dumpfile("risc_spm_wave.vcd");
        $dumpvars(0, memory_tb);
    end
    
    // Test verification task - improved with better timing
    task check_read(input [7:0] addr, input [7:0] expected);
        // Set address for reading
        address = addr;
        write_enable = 0;
        
        // Wait for read to propagate - longer delay
        #2; 
        
        if (data_out === expected) begin
            $display("PASS: Read from address 0x%h = 0x%h", addr, data_out);
        end else begin
            $display("FAIL: Read from address 0x%h", addr);
            $display("  Expected: 0x%h", expected);
            $display("  Got:      0x%h", data_out);
        end
    endtask
    
    // Task to write to memory with proper timing
    task write_mem(input [7:0] addr, input [7:0] data);
        address = addr;
        data_in = data;
        write_enable = 1;
        @(posedge clk);  // Wait for clock edge for write to occur
        #1;              // Wait a bit after the clock edge
        write_enable = 0;
        
        // Wait an additional small delay to ensure write completes
        #2;
    endtask
    
    // Main test sequence
    initial begin
        $display("Starting Memory Tests");
        
        // Initialize
        reset = 1;
        address = 0;
        write_enable = 0;
        data_in = 0;
        
        // Apply reset
        @(posedge clk);
        @(posedge clk);
        reset = 0;
        #2; // Wait a bit after reset
        
        //----------------------------------------------------------------------
        // Test 1: Reset behavior - Verify memory is cleared to 0
        //----------------------------------------------------------------------
        $display("\n=== Test 1: Reset behavior ===");
        check_read(8'h00, 8'h00);
        check_read(8'hFF, 8'h00);
        check_read(8'h55, 8'h00);
        
        //----------------------------------------------------------------------
        // Test 2: Basic write/read operations
        //----------------------------------------------------------------------
        $display("\n=== Test 2: Basic write/read operations ===");
        
        // Write to address 0x10
        write_mem(8'h10, 8'hA5);
        
        // Read from address 0x10
        check_read(8'h10, 8'hA5);
        
        // Write to address 0x20
        write_mem(8'h20, 8'h3C);
        
        // Read from address 0x20
        check_read(8'h20, 8'h3C);
        
        // Verify address 0x10 is still intact
        check_read(8'h10, 8'hA5);
        
        //----------------------------------------------------------------------
        // Test 3: Write to multiple addresses
        //----------------------------------------------------------------------
        $display("\n=== Test 3: Write to multiple addresses ===");
        
        // Write a pattern to several addresses
        for (int i = 0; i < 10; i++) begin
            write_mem(8'h30 + i, 8'h40 + i);
        end
        
        // Read back and verify
        for (int i = 0; i < 10; i++) begin
            check_read(8'h30 + i, 8'h40 + i);
        end
        
        //----------------------------------------------------------------------
        // Test 4: Overwrite existing data
        //----------------------------------------------------------------------
        $display("\n=== Test 4: Overwrite existing data ===");
        
        // Overwrite address 0x10
        write_mem(8'h10, 8'h5A);
        
        // Read back and verify
        check_read(8'h10, 8'h5A);
        
        //----------------------------------------------------------------------
        // Test 5: Test boundary addresses
        //----------------------------------------------------------------------
        $display("\n=== Test 5: Test boundary addresses ===");
        
        // Write to address 0x00 (lowest)
        write_mem(8'h00, 8'hB1);
        
        // Write to address 0xFF (highest)
        write_mem(8'hFF, 8'hB2);
        
        // Read back and verify
        check_read(8'h00, 8'hB1);
        check_read(8'hFF, 8'hB2);
        
        //----------------------------------------------------------------------
        // Test 6: Reset after data loaded
        //----------------------------------------------------------------------
        $display("\n=== Test 6: Reset after data loaded ===");
        
        // Apply reset
        reset = 1;
        @(posedge clk);
        @(posedge clk);
        reset = 0;
        #2; // Wait a bit after reset
        
        // Verify memory is cleared
        check_read(8'h00, 8'h00);
        check_read(8'h10, 8'h00);
        check_read(8'h20, 8'h00);
        check_read(8'hFF, 8'h00);
        
        $display("\nMemory Tests Complete");
        $finish;
    end
endmodule
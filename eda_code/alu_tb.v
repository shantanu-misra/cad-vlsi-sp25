// ALU Testbench
// Tests all ALU operations and zero flag behavior
module alu_tb;
    // Testbench signals
    logic [7:0] data_1;     // First operand 
    logic [7:0] data_2;     // Second operand
    logic [3:0] alu_op;     // ALU operation selector
    logic [7:0] result;     // Result
    logic zero_flag;        // Zero flag
    
    // Operation parameters - Matching the ALU constants
    localparam ADD = 4'b0001;
    localparam SUB = 4'b0010;
    localparam AND = 4'b0011;
    localparam NOT = 4'b0100;
    
    // Instantiate the ALU
    alu dut (
        .data_1(data_1),
        .data_2(data_2),
        .alu_op(alu_op),
        .result(result),
        .zero_flag(zero_flag)
    );
    
    // Test task to run a single ALU operation test
    task test_alu_op(
        input [3:0] op,
        input [7:0] d1,
        input [7:0] d2,
        input [7:0] expected_result,
        input expected_zero_flag,
        input string op_name
    );
        data_1 = d1;
        data_2 = d2;
        alu_op = op;
        #1; // Wait for combinational logic to settle
        
        if (result === expected_result && zero_flag === expected_zero_flag) begin
            $display("PASS: %s - data_1=0x%h, data_2=0x%h, result=0x%h, zero_flag=%b", 
                    op_name, d1, d2, result, zero_flag);
        end else begin
            $display("FAIL: %s - data_1=0x%h, data_2=0x%h", op_name, d1, d2);
            $display("  Expected: result=0x%h, zero_flag=%b", expected_result, expected_zero_flag);
            $display("  Got:      result=0x%h, zero_flag=%b", result, zero_flag);
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("Starting ALU Tests");
        
        //----------------------------------------------------------------------
        // ADD operation tests
        //----------------------------------------------------------------------
        $display("\n=== Testing ADD operation ===");
        
        // Basic addition
        test_alu_op(ADD, 8'h05, 8'h03, 8'h08, 1'b0, "ADD: 5 + 3 = 8");
        
        // Addition with zero result
        test_alu_op(ADD, 8'h00, 8'h00, 8'h00, 1'b1, "ADD: 0 + 0 = 0 (zero flag set)");
        
        // Addition with overflow
        test_alu_op(ADD, 8'hFF, 8'h01, 8'h00, 1'b1, "ADD: 255 + 1 = 0 (overflow, zero flag set)");
        
        // Negative numbers (two's complement)
        test_alu_op(ADD, 8'hFE, 8'h03, 8'h01, 1'b0, "ADD: -2 + 3 = 1");
        
        //----------------------------------------------------------------------
        // SUB operation tests
        //----------------------------------------------------------------------
        $display("\n=== Testing SUB operation ===");
        
        // Basic subtraction
        test_alu_op(SUB, 8'h03, 8'h08, 8'h05, 1'b0, "SUB: 8 - 3 = 5");
        
        // Subtraction with zero result
        test_alu_op(SUB, 8'h05, 8'h05, 8'h00, 1'b1, "SUB: 5 - 5 = 0 (zero flag set)");
        
        // Subtraction with underflow
        test_alu_op(SUB, 8'h06, 8'h05, 8'hFF, 1'b0, "SUB: 5 - 6 = -1 (255)");
        
        //----------------------------------------------------------------------
        // AND operation tests
        //----------------------------------------------------------------------
        $display("\n=== Testing AND operation ===");
        
        // Basic AND
        test_alu_op(AND, 8'h0F, 8'h33, 8'h03, 1'b0, "AND: 0F & 33 = 03");
        
        // AND with zero result
        test_alu_op(AND, 8'h0F, 8'hF0, 8'h00, 1'b1, "AND: 0F & F0 = 00 (zero flag set)");
        
        // AND with all bits set
        test_alu_op(AND, 8'hFF, 8'hFF, 8'hFF, 1'b0, "AND: FF & FF = FF");
        
        //----------------------------------------------------------------------
        // NOT operation tests
        //----------------------------------------------------------------------
        $display("\n=== Testing NOT operation ===");
        
        // Basic NOT (one's complement)
        test_alu_op(NOT, 8'h0F, 8'hXX, 8'hF0, 1'b0, "NOT: ~0F = F0");
        
        // NOT with zero result
        test_alu_op(NOT, 8'hFF, 8'hXX, 8'h00, 1'b1, "NOT: ~FF = 00 (zero flag set)");
        
        // NOT with all bits set
        test_alu_op(NOT, 8'h00, 8'hXX, 8'hFF, 1'b0, "NOT: ~00 = FF");
        
        //----------------------------------------------------------------------
        // Invalid operation test
        //----------------------------------------------------------------------
        $display("\n=== Testing invalid operation ===");
        
        // Invalid opcode should default to 0
        test_alu_op(4'b1111, 8'h0F, 8'h33, 8'h00, 1'b1, "Invalid opcode");
        
        $display("\nALU Tests Complete");
    end
endmodule
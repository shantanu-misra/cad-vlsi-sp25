module controller_tb;
    // Declare testbench signals.
    logic clk;
    logic reset;
    
    // Wires to connect to the controller outputs.
    logic load_pc, inc_pc, load_ir, load_addr_reg;
    logic load_r0, load_r1, load_r2, load_r3;
    logic [1:0] sel_alu_src1, sel_alu_src2;
    logic [3:0] alu_op;
    logic mem_write_enable, sel_mem_addr;
    logic [2:0] state_debug;
    
    // Controller status inputs.
    // ir_value drives the opcode and register fields.
    logic [7:0] ir_value;
    // zero_flag is used for branch (BRZ) decisions.
    logic zero_flag;
    
    // Instantiate the controller.
    controller uut (
        .clk(clk),
        .reset(reset),
        .load_pc(load_pc),
        .inc_pc(inc_pc),
        .load_ir(load_ir),
        .load_addr_reg(load_addr_reg),
        .load_r0(load_r0),
        .load_r1(load_r1),
        .load_r2(load_r2),
        .load_r3(load_r3),
        .sel_alu_src1(sel_alu_src1),
        .sel_alu_src2(sel_alu_src2),
        .alu_op(alu_op),
        .mem_write_enable(mem_write_enable),
        .sel_mem_addr(sel_mem_addr),
        .ir_value(ir_value),
        .zero_flag(zero_flag),
        .state_debug(state_debug)
    );
    
    // Clock generation: 10 ns period.
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Optional: Monitor outputs at each clock edge.
    always @(posedge clk) begin
        $display("Time=%0t | State=%b | IR=%h | ZF=%b || load_pc=%b, inc_pc=%b, load_ir=%b, load_addr_reg=%b, load_r0=%b, load_r1=%b, load_r2=%b, load_r3=%b, sel_alu_src1=%b, sel_alu_src2=%b, alu_op=%h, mem_we=%b, sel_mem_addr=%b",
                  $time, state_debug, ir_value, zero_flag,
                  load_pc, inc_pc, load_ir, load_addr_reg,
                  load_r0, load_r1, load_r2, load_r3,
                  sel_alu_src1, sel_alu_src2, alu_op,
                  mem_write_enable, sel_mem_addr);
    end
    
    // Stimulus process:
    // Manually assign IR values (and zero_flag when needed) to step through the FSM.
    // The controller’s next state depends on the current state and the opcode extracted
    // from ir_value. Here we give a sequence covering arithmetic, memory, branch, and halt.
    initial begin
        // Set initial conditions.
        reset = 1;
        ir_value = 8'h00;
        zero_flag = 0;
        @(posedge clk); @(posedge clk);
        reset = 0;
        @(posedge clk);
        
        // --- Test 1: Arithmetic Operation (ADD) ---
        // Set IR with opcode ADD (0001) and arbitrary register fields.
        $display("***** Testing Arithmetic: ADD (opcode=0001) *****");
        ir_value = 8'b0001_00_00; // ADD: opcode 0001, src=00, dst=00.
        @(posedge clk);
        // Allow several clock cycles to step through S_FET1, S_FET2, S_DEC, then S_EX1.
        repeat (4) @(posedge clk);
        
        // --- Test 2: Memory Operation (RD) ---
        $display("***** Testing Memory: RD (opcode=0101) *****");
        ir_value = 8'b0101_00_00; // RD: opcode 0101.
        @(posedge clk);
        repeat (4) @(posedge clk);
        
        // --- Test 3: Branch Operation (BR) ---
        $display("***** Testing Branch: BR (opcode=0111) *****");
        ir_value = 8'b0111_00_00; // BR: opcode 0111.
        @(posedge clk);
        repeat (4) @(posedge clk);
        
        // --- Test 4: Branch if Zero (BRZ) with zero_flag asserted ---
        $display("***** Testing Branch Zero: BRZ (opcode=1000) with zero_flag=1 *****");
        ir_value = 8'b1000_00_00; // BRZ: opcode 1000.
        zero_flag = 1;
        @(posedge clk);
        repeat (4) @(posedge clk);
        // Reset zero_flag.
        zero_flag = 0;
        
        // --- Test 5: HALT Instruction ---
        $display("***** Testing HALT (opcode=1111) *****");
        ir_value = 8'b1111_00_00; // HALT: opcode 1111.
        @(posedge clk);
        repeat (4) @(posedge clk);
        
        $finish;
    end
    
endmodule

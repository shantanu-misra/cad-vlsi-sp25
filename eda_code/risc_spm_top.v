module risc_spm_top (
    input logic clk,
    input logic reset,
    
    // External memory interface for programming
    input logic prog_mode,            // When high, external memory access is enabled
    input logic [7:0] prog_addr,      // Address for programming
    input logic prog_write,           // Write enable for programming
    input logic [7:0] prog_data_in,   // Data input for programming
    output logic [7:0] prog_data_out, // Data output for reading memory
    
    // Debug/status outputs
    output logic [7:0] output_data,   // R0 value output
    output logic [7:0] pc_debug,      // Program counter value
    output logic [7:0] ir_debug,      // Instruction register value
    output logic [2:0] state_debug,   // Current state of the FSM
    output logic halt_flag            // Indicates processor is halted
);
    // Internal signals
    logic [7:0] mem_address;
    logic mem_write_enable;
    logic [7:0] mem_data_out;
    logic [7:0] mem_data_in;
    
    // Controller to processor signals
    logic load_pc;
    logic inc_pc;
    logic load_ir;
    logic load_addr_reg;
    logic load_r0;
    logic load_r1;
    logic load_r2;
    logic load_r3;
    logic [1:0] sel_alu_src1;
    logic [1:0] sel_alu_src2;
    logic [3:0] alu_op;
    logic sel_mem_addr;
    
    // Status signals
    logic [7:0] r0_value;
    logic [7:0] ir_value;
    logic [7:0] pc_value;
    logic       zero_flag;
    
    // Multiplexed memory address and control based on programming mode
    logic [7:0] memory_address;
    logic memory_write_enable;
    logic [7:0] memory_data_in;
    logic [7:0] memory_data_out;
    
    // Address and control multiplexing
    assign memory_address = prog_mode ? prog_addr : mem_address;
    assign memory_write_enable = prog_mode ? prog_write : mem_write_enable;
    assign memory_data_in = prog_mode ? prog_data_in : mem_data_out;
    
    // Data output multiplexing
    assign mem_data_in = memory_data_out;
    assign prog_data_out = memory_data_out;
    
    // Processor instance (M0)
    processor processor_inst (
        .clk(clk),
        .reset(reset || prog_mode),   // Hold processor in reset during programming
        .mem_address(mem_address),
        .mem_data_out(mem_data_out),
        .mem_data_in(mem_data_in),
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
        .sel_mem_addr(sel_mem_addr),
        .r0_value(r0_value),
        .ir_value(ir_value),
        .pc_value(pc_value),
        .zero_flag(zero_flag)
    );
    
    // Controller instance (M1)
    controller controller_inst (
        .clk(clk),
        .reset(reset || prog_mode),   // Hold controller in reset during programming
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
    
    // Memory instance (M2)
    memory memory_inst (
        .clk(clk),
        .reset(reset && !prog_mode),  // Don't reset memory during programming mode
        .address(memory_address),
        .write_enable(memory_write_enable),
        .data_in(memory_data_in),
        .data_out(memory_data_out)
    );
    
    // Debug outputs
    assign output_data = r0_value;
    assign pc_debug = pc_value;
    assign ir_debug = ir_value;
    assign halt_flag = (state_debug == 3'b111); // S_HALT state
endmodule
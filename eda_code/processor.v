module processor (
    input  logic clk,
    input  logic reset,
    
    // Memory interface
    output logic [7:0] mem_address,
    output logic [7:0] mem_data_out,
    input  logic [7:0] mem_data_in,
    
    // Controller interface
    input  logic load_pc,
    input  logic inc_pc,
    input  logic load_ir,
    input  logic load_addr_reg,
    input  logic load_reg_y,
    input  logic load_reg_z,
    input  logic load_r0,
    input  logic load_r1,
    input  logic load_r2,
    input  logic load_r3,
    input  logic [1:0] sel_bus1_mux,
    input  logic [1:0] sel_bus2_mux,
    input  logic flush_pipeline,
    input  logic stall_pipeline,
    
    // Debug outputs
    output logic [7:0] r0_value,
    output logic [7:0] ir_value,
    output logic [7:0] pc_value,
    output logic       zero_flag
);
    // Registers
    logic [7:0] pc;            // Program counter
    logic [7:0] ir;            // Instruction register
    logic [7:0] r [0:3];       // General purpose registers (R0-R3)
    logic [7:0] addr_reg;      // Address register
    logic [7:0] reg_y;         // Y register for ALU
    logic       reg_z;         // Z register for zero flag
    
    // Buses
    logic [7:0] bus1;          // Bus 1 connects source registers to ALU or memory
    logic [7:0] bus2;          // Bus 2 connects ALU or memory to destination registers
    
    // ALU signals
    logic [7:0] alu_result;
    logic       alu_zero_flag;
    
    // Opcode definitions
    localparam NOP  = 4'b0000;
    localparam ADD  = 4'b0001;
    localparam SUB  = 4'b0010;
    localparam AND  = 4'b0011;
    localparam NOT  = 4'b0100;
    localparam RD   = 4'b0101;
    localparam WR   = 4'b0110;
    localparam BR   = 4'b0111;
    localparam BRZ  = 4'b1000;
    localparam HALT = 4'b1111;
    
    // ALU instance
    alu alu_inst (
        .data_1(bus1),         // First operand (from Bus 1)
        .data_2(reg_y),        // Second operand (from Reg Y)
        .alu_op(ir[7:4]),      // Operation from IR
        .result(alu_result),   // Result output
        .zero_flag(alu_zero_flag) // Zero flag
    );
    
    // Bus 1 multiplexer (source of data)
    always_comb begin
        case (sel_bus1_mux)
            2'b00: bus1 = pc;                  // PC
            2'b01: bus1 = r[0];                // R0
            2'b10: bus1 = addr_reg;            // Address register
            2'b11: bus1 = r[ir[3:2]];          // Source register from IR[3:2] (R0-R3)
                                              // For S_DEC: Used for destination register from IR[1:0]
        endcase
    end
    
    // Bus 2 multiplexer (destination data)
    always_comb begin
        case (sel_bus2_mux)
            2'b00: bus2 = alu_result;          // ALU result
            2'b01: bus2 = mem_data_in;         // Memory data
            2'b10: bus2 = bus1;                // Pass-through from Bus 1
            2'b11: bus2 = 8'h00;               // Zero (not used)
        endcase
    end
    
    // Memory address output
    assign mem_address = addr_reg;
    
    // Memory data output (for write operations)
    assign mem_data_out = bus1;
    
    // Register updates
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all registers
            pc      <= 8'h00;
            ir      <= 8'h00;
            r[0]    <= 8'h00;
            r[1]    <= 8'h00;
            r[2]    <= 8'h00;
            r[3]    <= 8'h00;
            addr_reg <= 8'h00;
            reg_y   <= 8'h00;
            reg_z   <= 1'b0;
        end else begin
            // Update registers based on control signals
            if (load_pc)
                pc <= bus2;
            else if (inc_pc)
                pc <= pc + 8'h01;
                
            if (load_ir)
                ir <= bus2;
                
            if (load_addr_reg)
                addr_reg <= bus2;
                
            if (load_reg_y)
                reg_y <= bus2;
                
            if (load_reg_z)
                reg_z <= alu_zero_flag;
                
            if (load_r0)
                r[0] <= bus2;
                
            if (load_r1)
                r[1] <= bus2;
                
            if (load_r2)
                r[2] <= bus2;
                
            if (load_r3)
                r[3] <= bus2;
        end
    end
    
    // Debug outputs
    assign r0_value = r[0];
    assign ir_value = ir;
    assign pc_value = pc;
    assign zero_flag = reg_z;
endmodule
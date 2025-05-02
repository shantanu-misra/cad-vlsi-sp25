module controller (
    input  logic clk,
    input  logic reset,
    
    // Processor interface
    output logic load_pc,
    output logic inc_pc,
    output logic load_ir,
    output logic load_addr_reg,
    output logic load_r0,
    output logic load_r1,
    output logic load_r2,
    output logic load_r3,
    output logic [1:0] sel_alu_src1,
    output logic [1:0] sel_alu_src2,
    output logic [3:0] alu_op,
    
    // Memory interface
    output logic mem_write_enable,
    output logic sel_mem_addr,
    
    // Status inputs from processor
    input  logic [7:0] ir_value,
    input  logic       zero_flag,
    
    // Debug output
    output logic [2:0] state_debug
);
    // FSM state definition
    typedef enum logic [2:0] {
        S_IDLE  = 3'b000,      // Initial idle state
        S_FET1  = 3'b001,      // First fetch cycle
        S_FET2  = 3'b010,      // Second fetch cycle
        S_DEC   = 3'b011,      // Decode instruction
        S_EX1   = 3'b100,      // Execute ALU operation
        S_RD1   = 3'b101,      // First cycle for memory/branch instructions
        S_RD2   = 3'b110,      // Second cycle for memory/branch instructions
        S_HALT  = 3'b111       // Halt state (must be 3'b111 for testbench)
    } state_t;
    
    state_t state, next_state;
    assign state_debug = state;
    
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
    
    // IR fields for convenience
    logic [3:0] opcode;
    logic [1:0] src_reg;
    logic [1:0] dst_reg;
    
    assign opcode = ir_value[7:4];
    assign src_reg = ir_value[3:2];
    assign dst_reg = ir_value[1:0];
    
    // Update the FSM state
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            state <= S_IDLE;
        else
            state <= next_state;
    end
    
    // Next-state logic
    always_comb begin
        next_state = state;
        case (state)
            S_IDLE:  next_state = S_FET1;
            S_FET1:  next_state = S_FET2;
            S_FET2:  next_state = S_DEC;
            S_DEC: begin
                case (opcode)
                    ADD, SUB, AND, NOT: next_state = S_EX1;
                    RD, WR, BR, BRZ:    next_state = S_RD1;
                    HALT:               next_state = S_HALT;
                    default:            next_state = S_FET1; // NOP or invalid
                endcase
            end
            S_EX1:   next_state = S_FET1;
            S_RD1:   next_state = S_RD2;
            S_RD2:   next_state = S_FET1;
            S_HALT:  next_state = S_HALT;
            default: next_state = S_IDLE;
        endcase
    end
    
    // Control signals
    always_comb begin
        // Default values
        load_pc = 1'b0;
        inc_pc = 1'b0;
        load_ir = 1'b0;
        load_addr_reg = 1'b0;
        load_r0 = 1'b0;
        load_r1 = 1'b0;
        load_r2 = 1'b0;
        load_r3 = 1'b0;
        sel_alu_src1 = 2'b00;
        sel_alu_src2 = 2'b00;
        alu_op = 4'b0000;
        mem_write_enable = 1'b0;
        sel_mem_addr = 1'b0;  // 0 = PC, 1 = addr_reg
        
        case (state)
            S_FET1: begin
                // Load address register with PC
                sel_mem_addr = 1'b0;    // Use PC for mem_address
            end
            
            S_FET2: begin
                // Fetch instruction from memory and increment PC
                load_ir = 1'b1;         // Load instruction register
                inc_pc = 1'b1;          // Increment PC
                sel_mem_addr = 1'b0;    // Use PC for mem_address
            end
            
            S_DEC: begin
                // Decode instruction - set ALU operation
                alu_op = opcode;        // Set ALU operation from opcode
            end
            
            S_EX1: begin
                // Execute ALU operations
                case (opcode)
                    ADD, SUB, AND: begin
                        sel_alu_src1 = 2'b00;  // Select source register (IR[3:2])
                        sel_alu_src2 = 2'b01;  // Select destination register (IR[1:0])
                        alu_op = opcode;       // Set ALU operation
                        
                        // Load destination register
                        case (dst_reg)
                            2'b00: load_r0 = 1'b1;
                            2'b01: load_r1 = 1'b1;
                            2'b10: load_r2 = 1'b1;
                            2'b11: load_r3 = 1'b1;
                        endcase
                    end
                    
                    NOT: begin
                        sel_alu_src1 = 2'b00;  // Select source register (IR[3:2])
                        alu_op = opcode;       // Set ALU operation
                        
                        // Load destination register
                        case (dst_reg)
                            2'b00: load_r0 = 1'b1;
                            2'b01: load_r1 = 1'b1;
                            2'b10: load_r2 = 1'b1;
                            2'b11: load_r3 = 1'b1;
                        endcase
                    end
                endcase
            end
            
            S_RD1: begin
                // Fetch second byte (immediate operand)
                load_addr_reg = 1'b1;   // Load address register with immediate
                inc_pc = 1'b1;          // Increment PC
                sel_mem_addr = 1'b0;    // Use PC for mem_address
            end
            
            S_RD2: begin
                sel_mem_addr = 1'b1;    // Use addr_reg for mem_address
                
                case (opcode)
                    RD: begin
                        // Read from memory to register
                        // Load destination register
                        case (dst_reg)
                            2'b00: load_r0 = 1'b1;
                            2'b01: load_r1 = 1'b1;
                            2'b10: load_r2 = 1'b1;
                            2'b11: load_r3 = 1'b1;
                        endcase
                    end
                    
                    WR: begin
                        // Write to memory
                        mem_write_enable = 1'b1;    // Enable memory write
                    end
                    
                    BR: begin
                        // Unconditional branch
                        load_pc = 1'b1;        // Load PC
                    end
                    
                    BRZ: begin
                        // Branch if zero
                        if (zero_flag) begin
                            load_pc = 1'b1;    // Load PC
                        end
                    end
                endcase
            end
            
            S_HALT: begin
                // No control signals asserted in halt state
            end
        endcase
    end
endmodule


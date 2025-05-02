module alu (
    input  logic [7:0] data_1,    // Operand 1
    input  logic [7:0] data_2,    // Operand 2
    input  logic [3:0] alu_op,    // Operation code
    output logic [7:0] result,    // Result
    output logic       zero_flag  // Zero flag
);
    localparam ADD = 4'b0001,
               SUB = 4'b0010,
               AND = 4'b0011,
               NOT = 4'b0100;
    
    always_comb begin
        case (alu_op)
            ADD:    result = data_2 + data_1;
            SUB:    result = data_2 - data_1;
            AND:    result = data_2 & data_1;
            NOT:    result = ~data_1;
            default: result = 8'h00;
        endcase
        zero_flag = (result == 8'h00);
    end
endmodule


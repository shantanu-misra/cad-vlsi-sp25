module memory (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] address,
    input  logic       write_enable,
    input  logic [7:0] data_in,
    output logic [7:0] data_out
);
    // 256 x 8-bit array.
    logic [7:0] mem [0:255];
    
    // Initialize memory (for simulation).
    initial begin
        for (int i = 0; i < 256; i = i + 1)
            mem[i] = 8'h00;
    end
    
    // Asynchronous read.
    assign data_out = mem[address];
    
    // Synchronous write and reset.
    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 256; i = i + 1)
                mem[i] <= 8'h00;
        end else if (write_enable) begin
            mem[address] <= data_in;
        end
    end
endmodule


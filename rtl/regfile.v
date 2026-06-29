`timescale 1ns / 1ps

module regfile #(
    parameter WIDTH    = 32,
    parameter NUM_REGS = 32,
    parameter ADDR_W   = 5
)(
    input  wire                clk,
    input  wire [ADDR_W-1:0]  rs1_addr,
    output wire [WIDTH-1:0]   rs1_data,
    input  wire [ADDR_W-1:0]  rs2_addr,
    output wire [WIDTH-1:0]   rs2_data,
    input  wire               wr_en,
    input  wire [ADDR_W-1:0]  rd_addr,
    input  wire [WIDTH-1:0]   rd_data
);

    // Register array declaration
    reg [WIDTH-1:0] registers [0:NUM_REGS-1];

    // Initialize all registers to 0
    integer i;
    initial begin
        for (i = 0; i < NUM_REGS; i = i + 1)
            registers[i] = {WIDTH{1'b0}};
    end

    // Write port (synchronous, posedge clk)
    // Triggers on the rising edge of the clock.
    // Data is written only if write enable (wr_en) is high AND the target address is not 0.
    always @(posedge clk) begin
        if (wr_en && (rd_addr != {ADDR_W{1'b0}})) begin
            registers[rd_addr] <= rd_data;
        end
    end

    // Read port 1 (combinational)
    // Continuous assignment evaluates immediately without waiting for a clock edge.
    // If the requested address is 0, it hardwires the output to 0. Otherwise, it fetches the register value.
    assign rs1_data = (rs1_addr == {ADDR_W{1'b0}}) ? {WIDTH{1'b0}} : registers[rs1_addr];

    // Read port 2 (combinational)
    // Functions identically to Read Port 1 for the second source register.
    assign rs2_data = (rs2_addr == {ADDR_W{1'b0}}) ? {WIDTH{1'b0}} : registers[rs2_addr];

endmodule

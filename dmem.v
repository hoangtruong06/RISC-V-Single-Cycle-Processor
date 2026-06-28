`timescale 1ns / 1ps

module dmem #(parameter DEPTH = 64)(
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [$clog2(DEPTH)+1:0] addr,
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);
    reg [31:0] mem [0:DEPTH-1];
    assign rdata = mem_read ? mem[addr[$clog2(DEPTH)+1:2]] : 32'b0;
    always @(posedge clk) begin
        if (mem_write) mem[addr[$clog2(DEPTH)+1:2]] <= wdata;
    end
    integer i;
    initial for (i = 0; i < DEPTH; i = i+1) mem[i] = 32'b0;
endmodule
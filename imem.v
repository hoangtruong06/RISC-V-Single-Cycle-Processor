`timescale 1ns / 1ps

module imem #(parameter DEPTH = 64)(
    input  wire [$clog2(DEPTH)+1:0] addr,
    output wire [31:0]              rdata
);
    reg [31:0] mem [0:DEPTH-1];
    assign rdata = mem[addr[$clog2(DEPTH)+1:2]];
    initial $readmemh("program.txt", mem);
endmodule
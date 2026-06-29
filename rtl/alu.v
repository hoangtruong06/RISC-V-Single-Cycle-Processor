`timescale 1ns / 1ps

module alu #(
    parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0]  A,
    input  wire [WIDTH-1:0]  B,
    input  wire [3:0]        alu_op,
    output reg  [WIDTH-1:0]  result,
    output wire              zero
);

    localparam ALU_ADD    = 4'b0000;
    localparam ALU_SUB    = 4'b0001;
    localparam ALU_AND    = 4'b0010;
    localparam ALU_OR     = 4'b0011;
    localparam ALU_XOR    = 4'b0100;
    localparam ALU_SLT    = 4'b0101;
    localparam ALU_SLL    = 4'b0110;
    localparam ALU_SRL    = 4'b0111;
    localparam ALU_SRA    = 4'b1000;
    localparam ALU_PASS_B = 4'b1001;

    assign zero = (result == {WIDTH{1'b0}});

    always @(*) begin
        case (alu_op)
            ALU_ADD:    result = A + B;
            ALU_SUB:    result = A - B;
            ALU_AND:    result = A & B;
            ALU_OR:     result = A | B;
            ALU_XOR:    result = A ^ B;
            ALU_SLT:    result = ($signed(A) < $signed(B)) ? {{(WIDTH-1){1'b0}}, 1'b1} : {WIDTH{1'b0}};
            ALU_SLL:    result = A << B[4:0];
            ALU_SRL:    result = A >> B[4:0];
            ALU_SRA:    result = $signed(A) >>> B[4:0];
            ALU_PASS_B: result = B;
            default:    result = {WIDTH{1'b0}};
        endcase
    end
endmodule

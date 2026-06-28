`timescale 1ns / 1ps

module immgen(
    input  wire [31:0] inst,
    output reg  [31:0] imm
);
    wire [6:0] opcode = inst[6:0];

    always @(*) begin
        case (opcode)
            7'b0010011,                            // I-type: ADDI
            7'b0000011: begin                      // I-type: LW
                imm = {{20{inst[31]}}, inst[31:20]};
            end
            
            7'b0100011: begin                      // S-type: SW
                imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            end
            
            7'b1100011: begin                      // B-type: BEQ
                imm = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
            end
            
            7'b1101111: begin                      // J-type: JAL
                imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
            end
            
            default: begin                         // R-type or unknown
                imm = 32'b0;                 
            end
        endcase
    end
endmodule
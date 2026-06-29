`timescale 1ns / 1ps

module control(
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg  [3:0] alu_op,
    output reg        alu_src,      // 0 = rs2_data,  1 = immediate
    output reg        mem_to_reg,   // 0 = ALU result, 1 = memory data
    output reg        reg_write,    // 1 = write to register file
    output reg        mem_read,     // 1 = read from data memory
    output reg        mem_write,    // 1 = write to data memory
    output reg        branch,       // 1 = BEQ instruction
    output reg        jump          // 1 = JAL instruction
);

    localparam OP_RTYPE = 7'b0110011;
    localparam OP_ITYPE = 7'b0010011;
    localparam OP_LW    = 7'b0000011;
    localparam OP_SW    = 7'b0100011;
    localparam OP_BEQ   = 7'b1100011;
    localparam OP_JAL   = 7'b1101111;

    always @(*) begin
        // Defaults: everything off
        // This prevents latches and covers the "Don't Care" (X) states with safe 0 values
        alu_op = 4'b0000; alu_src = 0; mem_to_reg = 0;
        reg_write = 0; mem_read = 0; mem_write = 0;
        branch = 0; jump = 0;

        case (opcode)
            OP_RTYPE: begin
                reg_write = 1;  // R-type writes result back to destination register (rd)
                // alu_src is default 0 because operand B is rs2
                
                // Determine alu_op based on funct3 and funct7[5]
                case (funct3)
                    3'b000: alu_op = funct7[5] ? 4'b0001 : 4'b0000; // 0001 for SUB, 0000 for ADD
                    3'b111: alu_op = 4'b0010;                       // AND
                    3'b110: alu_op = 4'b0011;                       // OR
                    3'b010: alu_op = 4'b0101;                       // SLT
                    default: alu_op = 4'b0000;
                endcase
            end
            
            OP_ITYPE: begin
                // ADDI instruction
                reg_write = 1;      // Write result to rd
                alu_src   = 1;      // Operand B comes from immediate generator
                alu_op    = 4'b0000; // Perform ADD operation (rs1 + imm)
            end
            
            OP_LW: begin
                // Load Word instruction
                reg_write  = 1;     // Write loaded data to rd
                alu_src    = 1;     // Operand B is immediate (offset for address)
                mem_read   = 1;     // Enable read from Data Memory
                mem_to_reg = 1;     // Route Data Memory output to Register File (not ALU result)
                alu_op     = 4'b0000; // Perform ADD to calculate memory address (rs1 + imm)
            end
            
            OP_SW: begin
                // Store Word instruction
                mem_write = 1;      // Enable write to Data Memory
                alu_src   = 1;      // Operand B is immediate (offset for address)
                alu_op    = 4'b0000; // Perform ADD to calculate memory address (rs1 + imm)
                // reg_write is 0 (default) because we don't write to register
            end
            
            OP_BEQ: begin
                // Branch if Equal instruction
                branch = 1;         // Assert branch signal for Next-PC Logic
                // alu_src is 0 (default) because we compare rs1 and rs2
                alu_op = 4'b0001;   // Perform SUB (rs1 - rs2). If zero flag == 1, they are equal
            end
            
            OP_JAL: begin
                // Jump and Link instruction
                jump      = 1;      // Assert jump signal for Next-PC Logic
                reg_write = 1;      // Save return address (PC+4) to rd
                // alu_src and alu_op are "Don't Cares" (X) here because Write-Back Mux directly selects PC+4
            end
            
            default: ; // NOP: all signals stay at defaults (0)
        endcase
    end
endmodule

`timescale 1ns / 1ps

module riscv_top(
    input wire clk,
    input wire rst,
    output wire [31:0] test_pc,
    output wire [31:0] test_alu_result,
    output wire [31:0] test_write_back
);

// =============================================================
// SECTION A: Program Counter 
// =============================================================
    (* dont_touch = "true" *) reg  [31:0] pc;
    wire [31:0] pc_plus4 = pc + 32'd4;                    // W_C
    wire [31:0] pc_next;                                   // W_R

    always @(posedge clk) begin
        if (rst)
            pc <= 32'b0;
        else
            pc <= pc_next;
    end

// =============================================================
// SECTION B: Instruction Fetch 
// =============================================================
    (* dont_touch = "true" *) wire [31:0] instruction;                              // W_B

    imem #(.DEPTH(64)) instruction_mem (
        .addr(pc[7:0]),                                    // W_A
        .rdata(instruction)                                // W_B
    );

// =============================================================
// SECTION C: Instruction Decode 
// =============================================================
    wire [6:0] opcode = instruction[6:0];                  // W_D
    wire [4:0] rd     = instruction[11:7];                 // W_E
    wire [2:0] funct3 = instruction[14:12];                // W_F
    wire [4:0] rs1    = instruction[19:15];                // W_G
    wire [4:0] rs2    = instruction[24:20];                // W_H
    wire [6:0] funct7 = instruction[31:25];                // W_I

// =============================================================
// SECTION D: Control Unit 
// =============================================================
    wire [3:0] ctrl_alu_op;
    wire       ctrl_alu_src, ctrl_mem_to_reg, ctrl_reg_write;
    wire       ctrl_mem_read, ctrl_mem_write, ctrl_branch, ctrl_jump;

    control ctrl (
        .opcode   (opcode),         // W_D — 7-bit opcode field
        .funct3   (funct3),         // W_F — 3-bit function field
        .funct7   (funct7),         // W_I — 7-bit function field
        .alu_op   (ctrl_alu_op),
        .alu_src  (ctrl_alu_src),
        .mem_to_reg(ctrl_mem_to_reg),
        .reg_write(ctrl_reg_write),
        .mem_read (ctrl_mem_read),
        .mem_write(ctrl_mem_write),
        .branch   (ctrl_branch),
        .jump     (ctrl_jump)
    );

// =============================================================
// SECTION E: Immediate Generator 
// =============================================================
    wire [31:0] imm_out;                                   // W_J

    immgen imm_gen (
        .inst (instruction),        // W_B — the full instruction
        .imm  (imm_out)             // W_J — the output immediate
    );

// =============================================================
// SECTION F: Register File
// =============================================================
    wire [31:0] rs1_data;                                  // W_K
    wire [31:0] rs2_data;                                  // W_L
    wire [31:0] write_back_data;   // defined in Section J  // W_Q

    regfile rf (
        .clk      (clk),
        .rs1_addr (rs1),            // W_G — source register 1
        .rs1_data (rs1_data),       // output: W_K
        .rs2_addr (rs2),            // W_H — source register 2
        .rs2_data (rs2_data),       // output: W_L
        .wr_en    (ctrl_reg_write), // Control signal enables writes
        .rd_addr  (rd),             // W_E — destination register
        .rd_data  (write_back_data) // W_Q — write-back data (Section J)
    );

// =============================================================
// SECTION G: ALU Source Mux 
// =============================================================
    wire [31:0] alu_operand_b;                             // W_M

    assign alu_operand_b = ctrl_alu_src ? imm_out          // 1: immediate (W_J)
                                        : rs2_data;        // 0: rs2 data (W_L)

// =============================================================
// SECTION H: ALU 
// =============================================================
    (* dont_touch = "true" *) wire [31:0] alu_result;                                // W_N
    wire        alu_zero;                                  // W_O

    alu #(.WIDTH(32)) main_alu (
        .A      (rs1_data),         // W_K — always rs1_data
        .B      (alu_operand_b),    // W_M — muxed operand
        .alu_op (ctrl_alu_op),      // from control unit
        .result (alu_result),       // output: W_N
        .zero   (alu_zero)          // output: W_O
    );

// =============================================================
// SECTION I: Data Memory 
// =============================================================
    wire [31:0] dmem_rdata;                                // W_P

    dmem #(.DEPTH(64)) data_mem (
        .clk      (clk),
        .mem_read (ctrl_mem_read),
        .mem_write(ctrl_mem_write),
        .addr     (alu_result[7:0]),                       // W_N (address)
        .wdata    (rs2_data),                              // W_L (store data)
        .rdata    (dmem_rdata)                             // W_P (load data)
    );

// =============================================================
// SECTION J: Write-Back Mux (MUX_B in datapath diagram)
// =============================================================
    (* dont_touch = "true" *) wire [31:0] write_back_data;
    assign write_back_data = ctrl_jump       ? pc_plus4    // W_C (pc+4 for JAL)
                           : ctrl_mem_to_reg ? dmem_rdata  // W_P (memory data for LW)
                           :                   alu_result; // W_N (ALU result for others)

// =============================================================
// SECTION K: Next-PC Logic (MUX_C in datapath diagram)
// =============================================================
    wire branch_taken = ctrl_branch && alu_zero;           // W_O (zero flag from ALU)

    assign pc_next = ctrl_jump    ? (pc + imm_out)         // W_J (jump target)
                   : branch_taken ? (pc + imm_out)         // W_J (branch target)
                   :                 pc_plus4;             // W_C (pc+4)
    assign test_pc         = pc;
    assign test_alu_result = alu_result;
    assign test_write_back = write_back_data;
endmodule

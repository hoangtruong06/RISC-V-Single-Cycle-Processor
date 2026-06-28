# RISC-V Single-Cycle Processor Core

This repository features the digital design and implementation of a 32-bit **RISC-V Single-Cycle Processor** written in Verilog. The core executes a subset of the RV32I base integer instruction set, featuring a complete Datapath and Control Unit, and is verified using a customized assembly test program.

> **Language:** Verilog HDL  
> **Synthesis & Simulation Tool:** AMD Xilinx Vivado 2025.2  
> **Target Board:** ZCU104 (Synthesis only)  

---
# Objectives
- Implement a control unit that decodes RISC-V instructions into control signals
- Understand the single-cycle processor datapath: how data flows through fetch, decode, execute, memory, and write-back--
- Integrate multiple sub-modules by connecting the correct signals- 
- Trace instructions through the datapath by hand
- Simulate and verify a processor executing a real RISC-V program
## Part 1: Datapath Architecture

The datapath is designed to execute instructions in a single clock cycle. Instead of a graphical block diagram, the data flow and routing logic are mapped out in the transition tables below.

### 1.1 — Datapath Routing & Signal Flow
This table describes how data propagates through the major architectural blocks during a single clock cycle.

| Source Block | Signal Code | Signal Name | Destination Block | Action / Purpose |
| :--- | :---: | :--- | :--- | :--- |
| **PC Register** | `W_A` | `pc` | **IMEM** & **Adder** | Fetches instruction; calculates `pc+4`. |
| **Instruction Memory** | `W_B` | `instruction` | **Decoder** | 32-bit raw instruction fed to decode logic. |
| **Decoder** | `W_E`, `W_G`, `W_H` | `rd`, `rs1`, `rs2` | **Register File** | Addresses for read/write registers. |
| **Decoder** | `W_D`, `W_F`, `W_I` | `opcode`, `funct3`, `funct7`| **Control Unit** | Drives control signals (mux selects, write enables). |
| **Decoder** | `W_J` | `imm_out` | **MUX_A** & **Adder** | Sign-extended immediate for ALU or Branch calc. |
| **Register File** | `W_K`, `W_L` | `rs1_data`, `rs2_data`| **ALU** & **MUX_A** | Source operands for execution. |
| **MUX_A** | `W_M` | `alu_operand_b` | **ALU** | Selects between `rs2_data` (0) and `imm` (1). |
| **ALU** | `W_N`, `W_O` | `alu_result`, `alu_zero` | **DMEM**, **MUX_B**, **MUX_C** | Computes addresses/values; determines branch condition. |
| **Data Memory** | `W_P` | `dmem_rdata` | **MUX_B** | Data loaded from memory. |
| **MUX_B** | `W_Q` | `write_back_data` | **Register File** | Selects `pc+4`, `alu_result`, or `dmem_rdata` to write back. |
| **MUX_C** | `W_R` | `pc_next` | **PC Register** | Updates PC: `pc+4` or Branch/Jump target. |
<img width="1148" height="542" alt="image" src="https://github.com/user-attachments/assets/b401da2c-23e3-41f9-a145-893480e5eb32" />

### 1.2 — Signal Reference Table

| Label | Width | Signal Name | Description |
| :---: | :---: | :--- | :--- |
| **W_A** | 32-bit | `pc` | Program counter (current instruction address) |
| **W_B** | 32-bit | `instruction` | Fetched instruction from IMEM |
| **W_C** | 32-bit | `pc_plus4` | `PC + 4` (next sequential address) |
| **W_D** | 7-bit | `opcode` | `instruction[6:0]` |
| **W_E** | 5-bit | `rd` | `instruction[11:7]` — destination register |
| **W_F** | 3-bit | `funct3` | `instruction[14:12]` |
| **W_G** | 5-bit | `rs1` | `instruction[19:15]` — source register 1 |
| **W_H** | 5-bit | `rs2` | `instruction[24:20]` — source register 2 |
| **W_I** | 7-bit | `funct7` | `instruction[31:25]` |
| **W_J** | 32-bit | `imm_out` | Sign-extended immediate from IMMGEN |
| **W_K** | 32-bit | `rs1_data` | Data read from register `rs1` |
| **W_L** | 32-bit | `rs2_data` | Data read from register `rs2` |
| **W_M** | 32-bit | `alu_operand_b`| ALU second operand (after MUX_A) |
| **W_N** | 32-bit | `alu_result` | ALU computation output |
| **W_O** | 1-bit | `alu_zero` | ALU zero flag (1 when result == 0) |
| **W_P** | 32-bit | `dmem_rdata` | Data read from Data Memory |
| **W_Q** | 32-bit | `write_back_data`| Data written back to Register File |
| **W_R** | 32-bit | `pc_next` | Next PC value (selected by MUX_C) |

---

## Part 2: Control Unit Implementation

The Control Unit is a purely combinational module. It decodes the `opcode`, `funct3`, and `funct7` fields to orchestrate the datapath via control signals.

### Truth Table for Control Signals
*Note: `X` denotes "don't care" conditions.*

| Instruction | `opcode` | `alu_op` | `alu_src` | `mem_to_reg` | `reg_write` | `mem_read` | `mem_write` | `branch` | `jump` |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **ADD** | `0110011` | `0000` | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| **SUB** | `0110011` | `0010` | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| **AND** | `0110011` | `0100` | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| **OR** | `0110011` | `0110` | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| **SLT** | `0110011` | `1010` | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| **ADDI** | `0010011` | `0000` | 1 | 0 | 1 | 0 | 0 | 0 | 0 |
| **LW** | `0000011` | `0000` | 1 | 1 | 1 | 1 | 0 | 0 | 0 |
| **SW** | `0100011` | `0000` | 1 | X | 0 | 0 | 1 | 0 | 0 |
| **BEQ** | `1100011` | `0010` | 0 | X | 0 | 0 | 0 | 1 | 0 |
| **JAL** | `1101111` | `XXXX` | X | X | 1 | 0 | 0 | 0 | 1 |

*(For R-type instructions sharing the `0110011` opcode, `funct3` and `funct7` are utilized to precisely determine the `alu_op` code).*

---

## Part 3: Test Program and Simulation

To verify the core's functionality, a custom assembly program was compiled into machine code and loaded into the Instruction Memory (`program.txt`). 
> 00100093
> 00B00113
> 00100193
00000293
001282B3
003080B3
0020A233
00020463
FF1FF06F
00000013
### Algorithm: Sum of Integers
The program computes the sum of integers from 1 to 10 using a loop. 
* **Expected Result:** Register `x5` should hold the value `55` (Hex: `0x37`) upon completion.

### Assembly Code & Memory Map

```assembly
# Address   Hex Code     Assembly Instruction  Effect
# -------------------------------------------------------------------------
  0x00      00100093     ADDI x1, x0, 1        x1 = 1          (i = 1)
  0x04      00B00113     ADDI x2, x0, 11       x2 = 11         (limit: i < 11)
  0x08      00100193     ADDI x3, x0, 1        x3 = 1          (step)
  0x0C      00000293     ADDI x5, x0, 0        x5 = 0          (sum = 0)
# --- LOOP START (0x10) ---
  0x10      001282B3     ADD  x5, x5, x1       x5 = x5 + x1    (sum += i)
  0x14      003080B3     ADD  x1, x1, x3       x1 = x1 + x3    (i += 1)
  0x18      0020A233     SLT  x4, x1, x2       x4 = (x1 < 11)? 1 : 0
  0x1C      00020463     BEQ  x4, x0, +8       If x4==0 (i>=11), skip to 0x24
  0x20      FF1FF06F     JAL  x0, -16          Jump back to 0x10 (loop)
# --- END PROGRAM (0x24) ---
  0x24      00000013     ADDI x0, x0, 0        NOP (Core halts logically)

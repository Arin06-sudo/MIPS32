# 5-Stage Pipelined MIPS32 Microprocessor

## 🚀 Project Overview

This repository contains the RTL implementation of a 32-bit, 5-stage pipelined MIPS microprocessor designed in **Verilog**. The architecture is heavily optimized for instruction throughput and demonstrates advanced digital design techniques for hazard detection and resolution.

Designed for FPGA synthesis (Xilinx Vivado), this project showcases a custom Instruction Set Architecture (ISA) and robust hardware mechanisms to handle data dependencies and structural conflicts seamlessly without stalling the pipeline unnecessarily.

## 🏗️ System Architecture

The processor implements the classic 5-stage RISC pipeline, ensuring one instruction completes per clock cycle under ideal conditions:

1. **Instruction Fetch (IF):** Fetches the next instruction from the Instruction Memory and increments the Program Counter (PC).
2. **Instruction Decode (ID):** Reads registers from the Register File and decodes the instruction opcode and operands.
3. **Execute (EX):** The Arithmetic Logic Unit (ALU) performs mathematical/logical operations or calculates memory addresses.
4. **Memory (MEM):** Handles reading from or writing to the Data Memory for load/store operations.
5. **Write-Back (WB):** Writes the final ALU result or memory data back to the destination register in the Register File.

## ⚡ Hazard Resolution & Advanced Features

A major focus of this project is maintaining maximum pipeline efficiency (IPC ≈ 1) through dedicated hazard-handling logic:

* **Forwarding Unit (Bypassing):** Actively detects Read-After-Write (RAW) data hazards. It routes data directly from the EX/MEM or MEM/WB pipeline registers back to the ALU inputs, significantly reducing the need for pipeline stalls (bubbles).
* **Structural Hazard Elimination:** * Implements a **two-phase clocking scheme** (writing on one edge, reading on the other) to prevent conflicts in the Register File.
  * Utilizes a **dual-port memory architecture**, separating Instruction Memory and Data Memory to ensure simultaneous fetch and memory access operations can occur in the same cycle.

## 📜 Supported Instruction Set Architecture (ISA)

The processor supports a custom subset of the MIPS32 ISA, handling core operational categories:

* **R-Type (Register):** `add`, `sub`, `and`, `or`, `slt`
* **I-Type (Immediate):** `addi`, `andi`, `ori`
* **Memory Operations:** `lw` (Load Word), `sw` (Store Word)
* **Control Flow:** `beq` (Branch on Equal), `j` (Jump)

## 🛠️ Technology Stack

* **Hardware Description Language:** Verilog
* **Synthesis & Simulation:** Xilinx Vivado
* **Target Architecture:** FPGA (General purpose RTL)

## 📂 File Structure

* `mips_top.v` - Top-level wrapper instantiating the datapath and control unit.
* `ALU.v` - Arithmetic Logic Unit for EX stage computations.
* `controller.v` - Main decoder and pipeline control signals.
* `forwarding_unit.v` - Hazard detection and data bypassing logic.
* `reg_bank.v` - 32-bit register file with two-phase clocking support.
* `dual_port_RAM.v` & `src/dmem.v` - Instruction and Data memories.
* `mips_test.v` - Simulation testbench for full pipeline verification.


## 📊 Simulation & Verification

The processor has been extensively verified using **Xilinx Vivado Simulator (XSim)**.

**Test Case Scenarios:**
1. **Basic Arithmetic:** Verified ALU outputs and Write-Back correctness for R-type and I-type instructions.
2. **Data Hazard Resolution:** Ran test programs with back-to-back dependent instructions to visually confirm the Forwarding Unit successfully bypassed data without stalling.
3. **Memory Integrity:** Validated accurate addressing and data retrieval during continuous `lw` and `sw` operations.
4. **Branching Logic:** Verified PC updates and pipeline flushing mechanisms during taken and untaken branch conditions.

---

## 🔧 How to Run

1. Clone the repository to your local machine.
2. Open **Vivado** and create a generic RTL project.
3. Add all Verilog files as Design Sources.
4. Add the `tb/mips_tb.v` file as a Simulation Source and set it as the top module.
5. Run **Behavioral Simulation** to observe the pipeline stages, forwarding multiplexers, and register updates in the waveform viewer.
